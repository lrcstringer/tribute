import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue } from 'firebase-admin/firestore';
import {
  db,
  membersCol,
  prayerRequestsCol,
  Timestamp,
  weekStart,
} from '../lib/firestore';

// ── prayerRequestCreate ────────────────────────────────────────────────────────

export const prayerRequestCreate = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, requestText, duration, anonymous } = request.data as {
      circleId: string;
      requestText: string;
      duration: 'THIS_WEEK' | 'ONGOING' | 'UNTIL_REMOVED';
      anonymous?: boolean;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!requestText?.trim()) throw new HttpsError('invalid-argument', 'requestText required');
    if (!['THIS_WEEK', 'ONGOING', 'UNTIL_REMOVED'].includes(duration)) {
      throw new HttpsError('invalid-argument', 'Invalid duration');
    }
    if (requestText.length > 500) {
      throw new HttpsError('invalid-argument', 'requestText exceeds 500 characters');
    }

    const uid = request.auth.uid;

    // Verify membership.
    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const memberData = memberSnap.data()!;
    const displayName = anonymous
      ? 'Anonymous'
      : (memberData['displayName'] as string | undefined) ?? 'Circle Member';

    // Calculate expiry for THIS_WEEK requests: end of Saturday (23:59:59).
    let expiresAt: Timestamp | null = null;
    if (duration === 'THIS_WEEK') {
      const sunday = weekStart();
      const saturday = new Date(sunday.getTime() + 6 * 86_400_000);
      saturday.setHours(23, 59, 59, 999);
      expiresAt = Timestamp.fromDate(saturday);
    }

    const ref = prayerRequestsCol(circleId).doc();
    await ref.set({
      id: ref.id,
      circleId,
      authorId: uid,
      authorDisplayName: displayName,
      requestText: requestText.trim(),
      duration,
      status: 'ACTIVE',
      answeredNote: null,
      prayerCount: 0,
      prayedByUserIds: [],
      createdAt: Timestamp.now(),
      answeredAt: null,
      expiresAt,
    });

    return { id: ref.id };
  }
);

// ── prayerPrayFor ──────────────────────────────────────────────────────────────

export const prayerPrayFor = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, requestId } = request.data as {
      circleId: string;
      requestId: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!requestId?.trim()) throw new HttpsError('invalid-argument', 'requestId required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const ref = prayerRequestsCol(circleId).doc(requestId);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Prayer request not found');
      const data = snap.data()!;

      // Idempotent: do nothing if already prayed.
      const alreadyPrayed = (data['prayedByUserIds'] as string[]).includes(uid);
      if (alreadyPrayed) return;

      tx.update(ref, {
        prayedByUserIds: FieldValue.arrayUnion(uid),
        prayerCount: FieldValue.increment(1),
      });
    });

    return { success: true };
  }
);

// ── prayerRequestMarkAnswered ──────────────────────────────────────────────────

export const prayerRequestMarkAnswered = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, requestId, answeredNote } = request.data as {
      circleId: string;
      requestId: string;
      answeredNote?: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!requestId?.trim()) throw new HttpsError('invalid-argument', 'requestId required');
    if (answeredNote && answeredNote.length > 200) {
      throw new HttpsError('invalid-argument', 'answeredNote exceeds 200 characters');
    }

    const uid = request.auth.uid;
    const ref = prayerRequestsCol(circleId).doc(requestId);
    const snap = await ref.get();

    if (!snap.exists) throw new HttpsError('not-found', 'Prayer request not found');
    if (snap.data()!['authorId'] !== uid) {
      throw new HttpsError('permission-denied', 'Only the author can mark a request as answered');
    }
    if (snap.data()!['status'] === 'ANSWERED') {
      return { success: true }; // Idempotent
    }

    await ref.update({
      status: 'ANSWERED',
      answeredAt: Timestamp.now(),
      answeredNote: answeredNote?.trim() ?? null,
    });

    return { success: true };
  }
);

// ── expirePrayerRequests (scheduled daily 00:00 UTC) ──────────────────────────

export const expirePrayerRequests = onSchedule(
  { schedule: '0 0 * * *', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const now = Timestamp.now();

    // Use a collection group query to find all expirable requests across circles.
    const expiredSnap = await db
      .collectionGroup('prayer_requests')
      .where('expiresAt', '<=', now)
      .where('status', '==', 'ACTIVE')
      .get();

    if (expiredSnap.empty) return;

    // Batch in chunks of 500 (Firestore limit).
    const chunks: typeof expiredSnap.docs[] = [];
    for (let i = 0; i < expiredSnap.docs.length; i += 500) {
      chunks.push(expiredSnap.docs.slice(i, i + 500));
    }

    for (const chunk of chunks) {
      const batch = db.batch();
      for (const doc of chunk) {
        batch.update(doc.ref, { status: 'EXPIRED' });
      }
      await batch.commit();
    }
  }
);
