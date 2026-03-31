import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import {
  db,
  membersCol,
  circlesCol,
  circleHabitsCol,
  habitDailySummaryCol,
  circleHabitMilestonesCol,
  Timestamp,
} from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

// ── circleCreateHabit ─────────────────────────────────────────────────────────

export const circleCreateHabit = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const {
      circleId,
      name,
      trackingType,
      targetValue,
      frequency,
      specificDays,
      anchorVerse,
      purposeStatement,
      description,
    } = request.data as {
      circleId: string;
      name: string;
      trackingType: 'CHECK_IN' | 'TIMED' | 'COUNT';
      targetValue?: number;
      frequency: 'DAILY' | 'WEEKLY' | 'SPECIFIC_DAYS';
      specificDays?: number[];
      anchorVerse?: string;
      purposeStatement?: string;
      description?: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!name?.trim()) throw new HttpsError('invalid-argument', 'name required');
    if (!['CHECK_IN', 'TIMED', 'COUNT'].includes(trackingType)) {
      throw new HttpsError('invalid-argument', 'Invalid trackingType');
    }
    if (!['DAILY', 'WEEKLY', 'SPECIFIC_DAYS'].includes(frequency)) {
      throw new HttpsError('invalid-argument', 'Invalid frequency');
    }

    const uid = request.auth.uid;

    // Admin-only permission check.
    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');
    if (memberSnap.data()!['role'] !== 'admin') {
      throw new HttpsError('permission-denied', 'Only admins can create circle habits');
    }

    const now = Timestamp.now();
    const ref = circleHabitsCol(circleId).doc();
    await ref.set({
      id: ref.id,
      circleId,
      createdById: uid,
      name: name.trim(),
      description: description?.trim() ?? null,
      trackingType,
      targetValue: targetValue ?? null,
      frequency,
      specificDays: specificDays ?? null,
      anchorVerse: anchorVerse?.trim() ?? null,
      purposeStatement: purposeStatement?.trim() ?? null,
      isActive: true,
      createdAt: now,
      startsAt: now,
      endsAt: null,
    });

    // Notify all circle members.
    const membersSnap = await membersCol(circleId).get();
    const memberIds = membersSnap.docs
      .map((d) => d.data()['userId'] as string)
      .filter((id) => id !== uid);

    if (memberIds.length > 0) {
      sendPushToUsers(memberIds, {
        title: 'New circle habit',
        body: `Your circle started "${name.trim()}". Join them?`,
        data: { type: 'CIRCLE_HABIT_CREATED', circleId, habitId: ref.id },
      }).catch(() => { /* non-fatal */ });
    }

    return { id: ref.id };
  }
);

// ── circleDeactivateHabit ─────────────────────────────────────────────────────

export const circleDeactivateHabit = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, habitId } = request.data as {
      circleId: string;
      habitId: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!habitId?.trim()) throw new HttpsError('invalid-argument', 'habitId required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');
    if (memberSnap.data()!['role'] !== 'admin') {
      throw new HttpsError('permission-denied', 'Only admins can deactivate circle habits');
    }

    const ref = circleHabitsCol(circleId).doc(habitId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Circle habit not found');

    await ref.update({ isActive: false });

    return { success: true };
  }
);

// ── circleCompleteHabitAggregation (Firestore trigger) ────────────────────────
// Triggered when a completion document is created, atomically updates the
// daily_summary so that all readers see consistent aggregate data.

export const circleCompleteHabitAggregation = onDocumentCreated(
  {
    document: 'circles/{circleId}/circle_habits/{habitId}/completions/{completionId}',
    region: 'us-central1',
  },
  async (event) => {
    const { circleId, habitId } = event.params;
    const completion = event.data?.data();
    if (!completion) return;

    const userId = completion['userId'] as string;
    const date = completion['date'] as string;

    const summaryRef = habitDailySummaryCol(circleId, habitId).doc(date);

    await db.runTransaction(async (tx) => {
      const summarySnap = await tx.get(summaryRef);

      if (summarySnap.exists) {
        const existing = summarySnap.data()!;
        const alreadyCounted = (existing['completedUserIds'] as string[]).includes(userId);
        if (alreadyCounted) return; // Idempotent — ignore duplicate writes.

        tx.update(summaryRef, {
          completedCount: FieldValue.increment(1),
          completedUserIds: FieldValue.arrayUnion(userId),
        });
      } else {
        // First completion of the day — fetch circle memberCount to seed totalMembers.
        const circleSnap = await tx.get(circlesCol().doc(circleId));
        const totalMembers = (circleSnap.data()?.['memberCount'] as number) ?? 1;

        tx.set(summaryRef, {
          id: date,
          habitId,
          totalMembers,
          completedCount: 1,
          completedUserIds: [userId],
        });
      }
    });

    // Check for circle habit milestones after the summary is updated (non-fatal).
    _checkCircleHabitMilestones(circleId, habitId).catch(() => { /* non-fatal */ });
  }
);

// ── circleHabitMilestoneCheck (Firestore trigger) ─────────────────────────────
// Also fires when a daily_summary is written directly (e.g. backfill),
// so milestones are never missed.

export const circleHabitMilestoneCheck = onDocumentWritten(
  {
    document: 'circles/{circleId}/circle_habits/{habitId}/daily_summary/{date}',
    region: 'us-central1',
  },
  async (event) => {
    const { circleId, habitId } = event.params;
    await _checkCircleHabitMilestones(circleId, habitId);
  }
);

// ── Internal helpers ──────────────────────────────────────────────────────────

const COMPLETION_THRESHOLDS = [10, 50, 100, 250, 500, 1000];

async function _checkCircleHabitMilestones(
  circleId: string,
  habitId: string
): Promise<void> {
  // Sum total completions across all daily summaries for this habit.
  const summariesSnap = await habitDailySummaryCol(circleId, habitId).get();
  const totalCompletions = summariesSnap.docs.reduce(
    (sum, d) => sum + ((d.data()['completedCount'] as number) ?? 0),
    0
  );

  if (totalCompletions === 0) return;

  // Fetch habit name once.
  const habitSnap = await circleHabitsCol(circleId).doc(habitId).get();
  if (!habitSnap.exists) return;
  const habitName = (habitSnap.data()!['name'] as string) ?? 'habit';

  const milestonesCol = circleHabitMilestonesCol(circleId);

  // For each threshold already crossed, ensure a milestone doc exists (idempotent).
  const crossed = COMPLETION_THRESHOLDS.filter((t) => totalCompletions >= t);
  await Promise.all(
    crossed.map(async (threshold) => {
      const docId = `${habitId}_completions_${threshold}`;
      const ref = milestonesCol.doc(docId);
      const snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          id: docId,
          circleId,
          habitId,
          habitName,
          milestoneValue: threshold,
          createdAt: Timestamp.now(),
        });
      }
    })
  );
}
