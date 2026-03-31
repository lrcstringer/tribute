import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import {
  db,
  membersCol,
  circlesCol,
  scriptureFocusCol,
  reflectionsCol,
  Timestamp,
  weekId,
  weekStart,
} from '../lib/firestore';

const bibleApiKey = defineSecret('BIBLE_API_KEY');

// Supported translations mapped to API.Bible IDs.
const BIBLE_IDS: Record<string, string> = {
  NIV: 'de4e12af7f28f599-02',
  ESV: '9879dbb7cfe39e4d-04',
  KJV: 'de4e12af7f28f599-01',
  NLT: '65eec8e0b60e656b-01',
  WEB: '9879dbb7cfe39e4d-01',
};

// ── circleFetchBiblePassage ────────────────────────────────────────────────────

export const circleFetchBiblePassage = onCall(
  { region: 'us-central1', secrets: [bibleApiKey] },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { reference, translation = 'NIV' } = request.data as {
      reference: string;
      translation?: string;
    };

    if (!reference?.trim()) throw new HttpsError('invalid-argument', 'reference required');

    const bibleId = BIBLE_IDS[translation.toUpperCase()];
    if (!bibleId) throw new HttpsError('invalid-argument', `Unsupported translation: ${translation}`);

    // Check cache first.
    const cacheKey = `${reference.toLowerCase().replace(/\s+/g, '_')}_${translation.toUpperCase()}`;
    const cacheRef = db.collection('bible_passage_cache').doc(cacheKey);
    const cached = await cacheRef.get();
    if (cached.exists) {
      return { text: cached.data()!['text'] as string };
    }

    // Fetch from API.Bible using search (accepts human-readable references like "John 3:16").
    const apiKey = bibleApiKey.value();
    const encodedRef = encodeURIComponent(reference);
    const url = `https://api.scripture.api.bible/v1/bibles/${bibleId}/search?query=${encodedRef}&limit=1`;

    const resp = await fetch(url, {
      headers: { 'api-key': apiKey },
    });

    if (!resp.ok) {
      // Fallback: return empty string, client handles manual entry.
      return { text: '' };
    }

    const json = await resp.json() as {
      data?: { passages?: Array<{ content?: string }> };
    };
    const text = (json.data?.passages?.[0]?.content ?? '').trim();

    // Cache result to reduce API calls.
    if (text) {
      await cacheRef.set({ text, reference, translation, cachedAt: Timestamp.now() });
    }

    return { text };
  }
);

// ── circleSetScriptureFocus ────────────────────────────────────────────────────

export const circleSetScriptureFocus = onCall(
  { region: 'us-central1', secrets: [bibleApiKey] },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, reference, translation = 'NIV', passageText, reflectionPrompt } =
      request.data as {
        circleId: string;
        reference: string;
        translation?: string;
        passageText: string;
        reflectionPrompt?: string;
      };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!reference?.trim()) throw new HttpsError('invalid-argument', 'reference required');
    if (!passageText?.trim()) throw new HttpsError('invalid-argument', 'passageText required');

    const uid = request.auth.uid;

    // Permission check: admin always allowed; any_member if settings permit.
    const [memberSnap, circleSnap] = await Promise.all([
      membersCol(circleId).doc(uid).get(),
      circlesCol().doc(circleId).get(),
    ]);

    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const settings = (circleSnap.data()?.['settings'] as Record<string, unknown>) ?? {};
    const permission = (settings['scriptureFocusPermission'] as string) ?? 'admin';
    const role = memberSnap.data()!['role'] as string;

    if (permission === 'admin' && role !== 'admin') {
      throw new HttpsError('permission-denied', 'Only admins can set Scripture focus');
    }

    const displayName =
      (memberSnap.data()!['displayName'] as string | undefined) ?? 'Circle Member';

    const currentWeekId = weekId();
    const weekStartDate = Timestamp.fromDate(weekStart());

    const ref = scriptureFocusCol(circleId).doc(currentWeekId);
    await ref.set(
      {
        id: currentWeekId,
        circleId,
        setById: uid,
        setByDisplayName: displayName,
        reference: reference.trim(),
        text: passageText.trim(),
        translation: translation.toUpperCase(),
        reflectionPrompt: reflectionPrompt?.trim() ?? null,
        weekStartDate,
        createdAt: Timestamp.now(),
      },
      { merge: false } // Replace entirely — only one focus per week.
    );

    return { weekId: currentWeekId };
  }
);

// ── circleSubmitReflection ────────────────────────────────────────────────────

export const circleSubmitReflection = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, weekId: wId, text } = request.data as {
      circleId: string;
      weekId: string;
      text: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!wId?.trim()) throw new HttpsError('invalid-argument', 'weekId required');
    if (!text?.trim()) throw new HttpsError('invalid-argument', 'text required');
    if (text.length > 300) throw new HttpsError('invalid-argument', 'Reflection exceeds 300 characters');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    // One reflection per user per week — use uid as document ID.
    const displayName =
      (memberSnap.data()!['displayName'] as string | undefined) ?? 'Circle Member';
    const ref = reflectionsCol(circleId, wId).doc(uid);

    // Enforce one-only rule inside a transaction.
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(ref);
      if (existing.exists) {
        throw new HttpsError('already-exists', 'You have already submitted a reflection this week');
      }
      tx.set(ref, {
        id: uid,
        authorId: uid,
        authorDisplayName: displayName,
        reflectionText: text.trim(),
        createdAt: Timestamp.now(),
      });
    });

    return { success: true };
  }
);

// ── Internal: fetch Bible passage via API.Bible (shared helper) ───────────────

export async function fetchPassageText(
  reference: string,
  translation: string,
  apiKey: string
): Promise<string> {
  const bibleId = BIBLE_IDS[translation.toUpperCase()] ?? BIBLE_IDS['NIV'];
  const encodedRef = encodeURIComponent(reference);
  const url = `https://api.scripture.api.bible/v1/bibles/${bibleId}/search?query=${encodedRef}&limit=1`;

  const resp = await fetch(url, { headers: { 'api-key': apiKey } });
  if (!resp.ok) return '';
  const json = await resp.json() as {
    data?: { passages?: Array<{ content?: string }> };
  };
  return (json.data?.passages?.[0]?.content ?? '').trim();
}
