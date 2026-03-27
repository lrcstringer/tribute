import * as z from 'zod';
import { FieldValue } from 'firebase-admin/firestore';
import { createTRPCRouter, protectedProcedure } from '../create-context';
import { db, usersCol, circlesCol, membersCol, Timestamp } from '../../lib/firestore';
import { auth } from '../../lib/admin';

export const userRouter = createTRPCRouter({
  getProfile: protectedProcedure.query(async ({ ctx }) => {
    const snap = await usersCol().doc(ctx.userId).get();
    const data = snap.data();
    return {
      userId: ctx.userId,
      displayName: (data?.displayName as string | null) ?? null,
      email: (data?.email as string | null) ?? null,
    };
  }),

  updateDisplayName: protectedProcedure
    .input(z.object({ displayName: z.string().min(1).max(50) }))
    .mutation(async ({ ctx, input }) => {
      await usersCol().doc(ctx.userId).update({
        displayName: input.displayName,
        updatedAt: Timestamp.now(),
      });
      return { userId: ctx.userId, displayName: input.displayName };
    }),

  deleteAccount: protectedProcedure.mutation(async ({ ctx }) => {
    const memberSnaps = await db.collectionGroup('members').where('userId', '==', ctx.userId).get();

    const batch = db.batch();
    for (const snap of memberSnaps.docs) {
      const circleId = snap.ref.parent.parent!.id;
      batch.delete(membersCol(circleId).doc(ctx.userId));
      batch.update(circlesCol().doc(circleId), {
        memberCount: FieldValue.increment(-1),
      });
    }
    batch.delete(usersCol().doc(ctx.userId));
    await batch.commit();

    await auth.deleteUser(ctx.userId);
    return { success: true };
  }),
});
