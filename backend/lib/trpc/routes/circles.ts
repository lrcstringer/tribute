import * as z from "zod";
import { TRPCError } from "@trpc/server";

import { createTRPCRouter, protectedProcedure } from "../create-context";
import { dbGet, dbSet, dbDelete, dbList } from "../../lib/db";

const MAX_CIRCLE_MEMBERS = 10_000;

interface Circle {
  id: string;
  name: string;
  description: string;
  creatorId: string;
  inviteCode: string;
  memberCount: number;
  createdAt: string;
}

interface CircleMember {
  circleId: string;
  userId: string;
  role: "admin" | "member";
  joinedAt: string;
  sosContactIds: string[];
}

interface HeatmapEntry {
  userId: string;
  circleId: string;
  weekData: Array<{ date: string; score: number }>;
  submittedAt: string;
}

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

async function getCircleMembers(circleId: string): Promise<CircleMember[]> {
  return (await dbGet<CircleMember[]>(`circle_members:${circleId}`)) || [];
}

async function setCircleMembers(circleId: string, members: CircleMember[]): Promise<void> {
  await dbSet(`circle_members:${circleId}`, members);
}

async function addCircleToUserIndex(userId: string, circleId: string): Promise<void> {
  const index = (await dbGet<string[]>(`user_circles:${userId}`)) || [];
  if (!index.includes(circleId)) {
    index.push(circleId);
    await dbSet(`user_circles:${userId}`, index);
  }
}

async function removeCircleFromUserIndex(userId: string, circleId: string): Promise<void> {
  const index = (await dbGet<string[]>(`user_circles:${userId}`)) || [];
  const filtered = index.filter((id) => id !== circleId);
  await dbSet(`user_circles:${userId}`, filtered);
}

async function findCircleByInviteCode(code: string): Promise<Circle | null> {
  const circleId = await dbGet<string>(`invite:${code.toUpperCase()}`);
  if (!circleId) return null;
  return await dbGet<Circle>(`circle:${circleId}`);
}

export const circlesRouter = createTRPCRouter({
  create: protectedProcedure
    .input(
      z.object({
        name: z.string().min(1).max(100),
        description: z.string().max(500).optional().default(""),
      }),
    )
    .mutation(async ({ ctx, input }) => {
      const circle: Circle = {
        id: crypto.randomUUID(),
        name: input.name,
        description: input.description,
        creatorId: ctx.userId,
        inviteCode: generateInviteCode(),
        memberCount: 1,
        createdAt: new Date().toISOString(),
      };

      await dbSet(`circle:${circle.id}`, circle);
      await dbSet(`invite:${circle.inviteCode}`, circle.id);

      const member: CircleMember = {
        circleId: circle.id,
        userId: ctx.userId,
        role: "admin",
        joinedAt: new Date().toISOString(),
        sosContactIds: [],
      };
      await setCircleMembers(circle.id, [member]);
      await addCircleToUserIndex(ctx.userId, circle.id);

      return {
        id: circle.id,
        name: circle.name,
        inviteCode: circle.inviteCode,
      };
    }),

  join: protectedProcedure
    .input(z.object({ inviteCode: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const circle = await findCircleByInviteCode(input.inviteCode);

      if (!circle) {
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "No prayer circle found with that invite code",
        });
      }

      if (circle.memberCount >= MAX_CIRCLE_MEMBERS) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "This prayer circle has reached its maximum capacity",
        });
      }

      const members = await getCircleMembers(circle.id);
      const alreadyMember = members.some((m) => m.userId === ctx.userId);

      if (alreadyMember) {
        return {
          id: circle.id,
          name: circle.name,
          alreadyMember: true,
        };
      }

      members.push({
        circleId: circle.id,
        userId: ctx.userId,
        role: "member",
        joinedAt: new Date().toISOString(),
        sosContactIds: [],
      });
      await setCircleMembers(circle.id, members);

      circle.memberCount = members.length;
      await dbSet(`circle:${circle.id}`, circle);
      await addCircleToUserIndex(ctx.userId, circle.id);

      return {
        id: circle.id,
        name: circle.name,
        alreadyMember: false,
      };
    }),

  list: protectedProcedure.query(async ({ ctx }) => {
    const circleIds = (await dbGet<string[]>(`user_circles:${ctx.userId}`)) || [];

    const userCircles: Array<{
      id: string;
      name: string;
      description: string;
      memberCount: number;
      role: string;
      inviteCode: string;
    }> = [];

    for (const circleId of circleIds) {
      const circle = await dbGet<Circle>(`circle:${circleId}`);
      if (!circle) continue;

      const members = await getCircleMembers(circleId);
      const membership = members.find((m) => m.userId === ctx.userId);
      if (!membership) continue;

      userCircles.push({
        id: circle.id,
        name: circle.name,
        description: circle.description,
        memberCount: circle.memberCount,
        role: membership.role,
        inviteCode: circle.inviteCode,
      });
    }

    return userCircles;
  }),

  getDetail: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .query(async ({ ctx, input }) => {
      const circle = await dbGet<Circle>(`circle:${input.circleId}`);
      if (!circle) {
        throw new TRPCError({ code: "NOT_FOUND", message: "Circle not found" });
      }

      const members = await getCircleMembers(input.circleId);
      const isMember = members.some((m) => m.userId === ctx.userId);

      if (!isMember) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "You are not a member of this circle",
        });
      }

      return {
        id: circle.id,
        name: circle.name,
        description: circle.description,
        memberCount: circle.memberCount,
        inviteCode: circle.inviteCode,
        createdAt: circle.createdAt,
        members: members.map((m) => ({
          userId: m.userId,
          role: m.role,
          joinedAt: m.joinedAt,
        })),
      };
    }),

  leave: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const members = await getCircleMembers(input.circleId);
      const filtered = members.filter((m) => m.userId !== ctx.userId);
      await setCircleMembers(input.circleId, filtered);
      await removeCircleFromUserIndex(ctx.userId, input.circleId);

      const circle = await dbGet<Circle>(`circle:${input.circleId}`);
      if (circle) {
        circle.memberCount = filtered.length;
        if (filtered.length === 0) {
          await dbDelete(`circle:${input.circleId}`);
          await dbDelete(`circle_members:${input.circleId}`);
          await dbDelete(`invite:${circle.inviteCode}`);
        } else {
          await dbSet(`circle:${input.circleId}`, circle);
        }
      }

      return { success: true };
    }),

  submitHeatmapData: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        weekData: z.array(
          z.object({
            date: z.string(),
            score: z.number().min(0).max(1),
          }),
        ),
      }),
    )
    .mutation(async ({ ctx, input }) => {
      const entry: HeatmapEntry = {
        userId: ctx.userId,
        circleId: input.circleId,
        weekData: input.weekData,
        submittedAt: new Date().toISOString(),
      };
      await dbSet(`heatmap:${input.circleId}:${ctx.userId}`, entry);
      return { success: true };
    }),

  getCircleHeatmap: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        weeksBack: z.number().min(1).max(52).optional().default(12),
      }),
    )
    .query(async ({ ctx, input }) => {
      const members = await getCircleMembers(input.circleId);
      const dateScores: Record<string, { total: number; count: number }> = {};

      for (const member of members) {
        const entry = await dbGet<HeatmapEntry>(`heatmap:${input.circleId}:${member.userId}`);
        if (!entry) continue;
        for (const day of entry.weekData) {
          if (!dateScores[day.date]) {
            dateScores[day.date] = { total: 0, count: 0 };
          }
          dateScores[day.date].total += day.score;
          dateScores[day.date].count += 1;
        }
      }

      const aggregatedData = Object.entries(dateScores).map(([date, { total, count }]) => ({
        date,
        averageScore: count > 0 ? total / count : 0,
        memberCount: count,
      }));

      return {
        circleId: input.circleId,
        aggregatedData,
      };
    }),

  getSundaySummary: protectedProcedure
    .input(z.object({ circleId: z.string() }))
    .query(async ({ ctx, input }) => {
      const members = await getCircleMembers(input.circleId);
      let activeCount = 0;
      let totalScore = 0;

      for (const member of members) {
        const entry = await dbGet<HeatmapEntry>(`heatmap:${input.circleId}:${member.userId}`);
        if (entry && entry.weekData.length > 0) {
          activeCount++;
          const avg = entry.weekData.reduce((sum, d) => sum + d.score, 0) / entry.weekData.length;
          totalScore += avg;
        }
      }

      return {
        circleId: input.circleId,
        weekOf: new Date().toISOString(),
        totalMembers: members.length,
        activeMembers: activeCount,
        averageScore: activeCount > 0 ? totalScore / activeCount : 0,
        topStreaks: [] as Array<{ userId: string; streak: number }>,
      };
    }),
});
