import * as z from "zod";
import { TRPCError } from "@trpc/server";

import { createTRPCRouter, protectedProcedure } from "../create-context";
import { dbGet, dbSet } from "../../lib/db";

const MAX_SOS_RECIPIENTS = 20;

interface SOSRequest {
  id: string;
  senderId: string;
  circleId: string;
  message: string;
  recipientIds: string[];
  createdAt: string;
}

async function getCircleSOS(circleId: string): Promise<SOSRequest[]> {
  return (await dbGet<SOSRequest[]>(`sos:${circleId}`)) || [];
}

async function addSOSRequest(circleId: string, sos: SOSRequest): Promise<void> {
  const existing = await getCircleSOS(circleId);
  existing.unshift(sos);
  const trimmed = existing.slice(0, 100);
  await dbSet(`sos:${circleId}`, trimmed);
}

export const sosRouter = createTRPCRouter({
  send: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        message: z.string().max(500).optional().default("Please pray for me"),
        recipientIds: z
          .array(z.string())
          .max(MAX_SOS_RECIPIENTS, {
            message: `SOS can only be sent to ${MAX_SOS_RECIPIENTS} people maximum`,
          }),
      }),
    )
    .mutation(async ({ ctx, input }) => {
      if (input.recipientIds.length > MAX_SOS_RECIPIENTS) {
        throw new TRPCError({
          code: "BAD_REQUEST",
          message: `SOS prayer requests can only be sent to ${MAX_SOS_RECIPIENTS} people maximum`,
        });
      }

      const sos: SOSRequest = {
        id: crypto.randomUUID(),
        senderId: ctx.userId,
        circleId: input.circleId,
        message: input.message,
        recipientIds: input.recipientIds,
        createdAt: new Date().toISOString(),
      };

      await addSOSRequest(input.circleId, sos);

      for (const recipientId of input.recipientIds) {
        const pushToken = await dbGet<string>(`pushtoken:${recipientId}`);
        if (pushToken) {
          await sendPushNotification(pushToken, {
            title: "SOS Prayer Request",
            body: input.message,
            data: { circleId: input.circleId, sosId: sos.id },
          });
        }
      }

      return {
        id: sos.id,
        recipientCount: input.recipientIds.length,
      };
    }),

  getRecent: protectedProcedure
    .input(
      z.object({
        circleId: z.string().optional(),
        limit: z.number().min(1).max(50).optional().default(20),
      }),
    )
    .query(async ({ ctx, input }) => {
      const userCircleIds = (await dbGet<string[]>(`user_circles:${ctx.userId}`)) || [];

      let allSOS: SOSRequest[] = [];

      if (input.circleId) {
        allSOS = await getCircleSOS(input.circleId);
      } else {
        for (const cid of userCircleIds) {
          const circleSOS = await getCircleSOS(cid);
          allSOS.push(...circleSOS);
        }
      }

      const filtered = allSOS.filter(
        (s) => s.recipientIds.includes(ctx.userId) || s.senderId === ctx.userId,
      );

      return filtered
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, input.limit)
        .map((s) => ({
          id: s.id,
          senderId: s.senderId,
          circleId: s.circleId,
          message: s.message,
          createdAt: s.createdAt,
          isMine: s.senderId === ctx.userId,
        }));
    }),

  setSOSContacts: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        contactUserIds: z
          .array(z.string())
          .max(MAX_SOS_RECIPIENTS, {
            message: `You can select up to ${MAX_SOS_RECIPIENTS} SOS contacts`,
          }),
      }),
    )
    .mutation(async ({ ctx, input }) => {
      await dbSet(`soscontacts:${input.circleId}:${ctx.userId}`, input.contactUserIds);
      return {
        circleId: input.circleId,
        contactCount: input.contactUserIds.length,
      };
    }),
});

async function sendPushNotification(
  pushToken: string,
  notification: { title: string; body: string; data?: Record<string, string> },
): Promise<void> {
  try {
    await fetch("https://exp.host/--/api/v2/push/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        to: pushToken,
        title: notification.title,
        body: notification.body,
        sound: "default",
        data: notification.data,
      }),
    });
  } catch {
    // silently fail push notifications
  }
}
