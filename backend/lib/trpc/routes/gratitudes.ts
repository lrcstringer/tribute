import * as z from "zod";
import { TRPCError } from "@trpc/server";

import { createTRPCRouter, protectedProcedure } from "../create-context";
import { dbGet, dbSet } from "../../lib/db";

interface SharedGratitude {
  id: string;
  circleId: string;
  userId: string;
  displayName: string | null;
  gratitudeText: string;
  isAnonymous: boolean;
  sharedAt: string;
  deleted: boolean;
}

interface UserRecord {
  id: string;
  appleUserId: string;
  email: string | null;
  displayName: string | null;
  pushToken: string | null;
}

interface CircleMember {
  circleId: string;
  userId: string;
  role: "admin" | "member";
  joinedAt: string;
  sosContactIds: string[];
}

async function getCircleGratitudes(circleId: string): Promise<SharedGratitude[]> {
  return (await dbGet<SharedGratitude[]>(`gratitudes:${circleId}`)) || [];
}

async function setCircleGratitudes(circleId: string, gratitudes: SharedGratitude[]): Promise<void> {
  await dbSet(`gratitudes:${circleId}`, gratitudes);
}

async function getCircleMembers(circleId: string): Promise<CircleMember[]> {
  return (await dbGet<CircleMember[]>(`circle_members:${circleId}`)) || [];
}

function getWeekStart(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day;
  d.setDate(diff);
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
      }),
    )
    .mutation(async ({ ctx, input }) => {
      const user = await dbGet<UserRecord>(`user:${ctx.userId}`);
      const name = input.displayName || user?.displayName || null;

      const results: { circleId: string; gratitudeId: string }[] = [];

      for (const circleId of input.circleIds) {
        const members = await getCircleMembers(circleId);
        const isMember = members.some((m) => m.userId === ctx.userId);
        if (!isMember) continue;

        const gratitude: SharedGratitude = {
          id: crypto.randomUUID(),
          circleId,
          userId: ctx.userId,
          displayName: name,
          gratitudeText: input.gratitudeText,
          isAnonymous: input.isAnonymous,
          sharedAt: new Date().toISOString(),
          deleted: false,
        };

        const existing = await getCircleGratitudes(circleId);
        existing.unshift(gratitude);
        const trimmed = existing.slice(0, 500);
        await setCircleGratitudes(circleId, trimmed);

        results.push({ circleId, gratitudeId: gratitude.id });
      }

      return { shared: results };
    }),

  getWall: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        weeksBack: z.number().min(0).max(52).optional().default(0),
      }),
    )
    .query(async ({ ctx, input }) => {
      const members = await getCircleMembers(input.circleId);
      const isMember = members.some((m) => m.userId === ctx.userId);
      if (!isMember) {
        throw new TRPCError({ code: "FORBIDDEN", message: "Not a member of this circle" });
      }

      const all = await getCircleGratitudes(input.circleId);
      const active = all.filter((g) => !g.deleted);

      const now = new Date();
      const targetWeekStart = getWeekStart(now);
      targetWeekStart.setDate(targetWeekStart.getDate() - input.weeksBack * 7);
      const targetWeekEnd = new Date(targetWeekStart);
      targetWeekEnd.setDate(targetWeekEnd.getDate() + 7);

      const filtered = active.filter((g) => {
        const d = new Date(g.sharedAt);
        return d >= targetWeekStart && d < targetWeekEnd;
      });

      return {
        circleId: input.circleId,
        weeksBack: input.weeksBack,
        gratitudes: filtered
          .sort((a, b) => new Date(b.sharedAt).getTime() - new Date(a.sharedAt).getTime())
          .map((g) => ({
            id: g.id,
            gratitudeText: g.gratitudeText,
            isAnonymous: g.isAnonymous,
            displayName: g.isAnonymous ? null : g.displayName,
            sharedAt: g.sharedAt,
            isMine: g.userId === ctx.userId,
          })),
      };
    }),

  delete: protectedProcedure
    .input(z.object({ circleId: z.string(), gratitudeId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const all = await getCircleGratitudes(input.circleId);
      const gratitude = all.find((g) => g.id === input.gratitudeId);

      if (!gratitude) {
        throw new TRPCError({ code: "NOT_FOUND", message: "Gratitude not found" });
      }
      if (gratitude.userId !== ctx.userId) {
        throw new TRPCError({ code: "FORBIDDEN", message: "You can only delete your own gratitudes" });
      }

      gratitude.deleted = true;
      await setCircleGratitudes(input.circleId, all);

      return { success: true };
    }),

  getNewCount: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .query(async ({ ctx, input }) => {
      const lastSeen = await dbGet<string>(`gratitude_seen:${input.circleId}:${ctx.userId}`);
      const all = await getCircleGratitudes(input.circleId);
      const active = all.filter((g) => !g.deleted);

      let count = 0;
      if (lastSeen) {
        const lastSeenDate = new Date(lastSeen);
        count = active.filter((g) => new Date(g.sharedAt) > lastSeenDate).length;
      } else {
        const weekStart = getWeekStart(new Date());
        count = active.filter((g) => new Date(g.sharedAt) >= weekStart).length;
      }

      return { circleId: input.circleId, newCount: count };
    }),

  markSeen: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      await dbSet(`gratitude_seen:${input.circleId}:${ctx.userId}`, new Date().toISOString());
      return { success: true };
    }),

  getWeekCount: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .query(async ({ ctx, input }) => {
      const all = await getCircleGratitudes(input.circleId);
      const weekStart = getWeekStart(new Date());
      const count = all.filter((g) => new Date(g.sharedAt) >= weekStart).length;
      return { circleId: input.circleId, weekCount: count };
    }),
});
