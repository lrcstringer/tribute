import * as z from "zod";

import { createTRPCRouter, protectedProcedure } from "../create-context";

export const userRouter = createTRPCRouter({
  getProfile: protectedProcedure.query(async ({ ctx }) => {
    return {
      userId: ctx.userId,
    };
  }),

  updateDisplayName: protectedProcedure
    .input(z.object({ displayName: z.string().min(1).max(50) }))
    .mutation(async ({ ctx, input }) => {
      return {
        userId: ctx.userId,
        displayName: input.displayName,
      };
    }),

  deleteAccount: protectedProcedure.mutation(async ({ ctx }) => {
    return { success: true };
  }),
});
