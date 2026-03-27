import * as z from 'zod';
import { createTRPCRouter, protectedProcedure } from '../create-context';
import { usersCol, Timestamp } from '../../lib/firestore';

export const authRouter = createTRPCRouter({
  // Called after Firebase Auth Apple Sign In completes on the client.
  // Ensures a Firestore user document exists and is up to date.
  ensureProfile: protectedProcedure
    .input(
      z.object({
        displayName: z.string().nullable().optional(),
        email: z.string().nullable().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const ref = usersCol().doc(ctx.userId);
      const snap = await ref.get();
      const isNew = !snap.exists;

      if (isNew) {
        await ref.set({
          id: ctx.userId,
          appleUserId: ctx.userId,
          email: input.email ?? null,
          displayName: input.displayName ?? null,
          fcmToken: null,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        });
      } else {
        const data = snap.data()!;
        const updates: Record<string, unknown> = { updatedAt: Timestamp.now() };
        if (input.displayName && !data.displayName) updates.displayName = input.displayName;
        if (input.email && !data.email) updates.email = input.email;
        if (Object.keys(updates).length > 1) await ref.update(updates);
      }

      const final = isNew ? snap : await ref.get();
      return {
        userId: ctx.userId,
        displayName: final.data()?.displayName ?? input.displayName ?? null,
        isNewUser: isNew,
      };
    }),

  registerPushToken: protectedProcedure
    .input(z.object({ fcmToken: z.string() }))
    .mutation(async ({ ctx, input }) => {
      await usersCol().doc(ctx.userId).update({
        fcmToken: input.fcmToken,
        updatedAt: Timestamp.now(),
      });
      return { success: true };
    }),
});
