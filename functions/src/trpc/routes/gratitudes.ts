import * as z from 'zod';
import { TRPCError } from '@trpc/server';
import { createTRPCRouter, protectedProcedure } from '../create-context';
import {
  usersCol,
  gratitudesCol,
  membersCol,
  userSeenGratitudeDoc,
  Timestamp,
} from '../../lib/firestore';
import { checkGratitudeMilestones } from './circles';

function getWeekStart(date: Date): Date {
  const d = new Date(date);
  d.setDate(d.getDate() - d.getDay());
  d.setHours(0, 0, 0, 0);
  return d;
}

function getTodayStart(): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

export const gratitudesRouter = createTRPCRouter({
  share: protectedProcedure
    .input(
      z.object({
        circleIds: z.array(z.string()).min(1).max(10),
        gratitudeText: z.string().max(1000),
        isAnonymous: z.boolean(),
        displayName: z.string().nullable().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const userSnap = await usersCol().doc(ctx.userId).get();
      const name = input.displayName ?? userSnap.data()?.displayName ?? null;
      const results: Array<{ circleId: string; gratitudeId: string }> = [];
      const todayStart = getTodayStart();

      for (const circleId of input.circleIds) {
        const memberSnap = await membersCol(circleId).doc(ctx.userId).get();
        if (!memberSnap.exists) continue;

        const gratitudeId = crypto.randomUUID();
        await gratitudesCol(circleId).doc(gratitudeId).set({
          id: gratitudeId,
          circleId,
          userId: ctx.userId,
          displayName: name,
          gratitudeText: input.gratitudeText,
          isAnonymous: input.isAnonymous,
          sharedAt: Timestamp.now(),
          deleted: false,
        });

        results.push({ circleId, gratitudeId });

        // Increment gratitude day totals if user hasn't already shared today in this circle
        const todayCountSnap = await gratitudesCol(circleId)
          .where('userId', '==', ctx.userId)
          .where('sharedAt', '>=', Timestamp.fromDate(todayStart))
          .where('deleted', '==', false)
          .count()
          .get();

        // If this is the first gratitude today (count was 0 before this insert), check milestones
        if (todayCountSnap.data().count === 1) {
          checkGratitudeMilestones(circleId).catch(() => undefined);
        }
      }

      return { shared: results };
    }),

  getWall: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        weeksBack: z.number().min(0).max(52).optional().default(0),
      })
    )
    .query(async ({ ctx, input }) => {
      const memberSnap = await membersCol(input.circleId).doc(ctx.userId).get();
      if (!memberSnap.exists) {
        throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a member of this circle' });
      }

      const weekStart = getWeekStart(new Date());
      weekStart.setDate(weekStart.getDate() - input.weeksBack * 7);
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 7);

      const snap = await gratitudesCol(input.circleId)
        .where('deleted', '==', false)
        .where('sharedAt', '>=', Timestamp.fromDate(weekStart))
        .where('sharedAt', '<', Timestamp.fromDate(weekEnd))
        .orderBy('sharedAt', 'desc')
        .limit(100)
        .get();

      return {
        circleId: input.circleId,
        weeksBack: input.weeksBack,
        gratitudes: snap.docs.map((d) => {
          const g = d.data();
          return {
            id: g.id as string,
            gratitudeText: g.gratitudeText as string,
            isAnonymous: g.isAnonymous as boolean,
            displayName: g.isAnonymous ? null : (g.displayName as string | null),
            sharedAt: (g.sharedAt as FirebaseFirestore.Timestamp).toDate().toISOString(),
            isMine: g.userId === ctx.userId,
          };
        }),
      };
    }),

  delete: protectedProcedure
    .input(z.object({ circleId: z.string(), gratitudeId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const ref = gratitudesCol(input.circleId).doc(input.gratitudeId);
      const snap = await ref.get();

      if (!snap.exists) throw new TRPCError({ code: 'NOT_FOUND', message: 'Gratitude not found' });
      if (snap.data()!.userId !== ctx.userId) {
        throw new TRPCError({ code: 'FORBIDDEN', message: 'You can only delete your own gratitudes' });
      }

      await ref.update({ deleted: true });
      return { success: true };
    }),

  getNewCount: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .query(async ({ ctx, input }) => {
      const seenSnap = await userSeenGratitudeDoc(input.circleId, ctx.userId).get();
      const lastSeen = seenSnap.exists
        ? (seenSnap.data()!.lastSeen as FirebaseFirestore.Timestamp).toDate()
        : getWeekStart(new Date());

      const countSnap = await gratitudesCol(input.circleId)
        .where('deleted', '==', false)
        .where('sharedAt', '>', Timestamp.fromDate(lastSeen))
        .count()
        .get();

      return { circleId: input.circleId, newCount: countSnap.data().count };
    }),

  markSeen: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      await userSeenGratitudeDoc(input.circleId, ctx.userId).set({
        userId: ctx.userId,
        lastSeen: Timestamp.now(),
      });
      return { success: true };
    }),

  getWeekCount: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .query(async ({ ctx, input }) => {
      const memberSnap = await membersCol(input.circleId).doc(ctx.userId).get();
      if (!memberSnap.exists) throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a member' });

      const weekStart = getWeekStart(new Date());
      const countSnap = await gratitudesCol(input.circleId)
        .where('deleted', '==', false)
        .where('sharedAt', '>=', Timestamp.fromDate(weekStart))
        .count()
        .get();

      return { circleId: input.circleId, weekCount: countSnap.data().count };
    }),
});
