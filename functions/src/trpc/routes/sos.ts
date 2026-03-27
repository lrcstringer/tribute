import * as z from 'zod';
import { TRPCError } from '@trpc/server';
import { createTRPCRouter, protectedProcedure } from '../create-context';
import { db, sosRequestsCol, membersCol, sosContactsDoc, Timestamp } from '../../lib/firestore';
import { sendPushToUsers } from '../../lib/fcm';

const MAX_SOS_RECIPIENTS = 20;

export const sosRouter = createTRPCRouter({
  send: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        message: z.string().max(500).optional().default('Please pray for me'),
        recipientIds: z.array(z.string()).max(MAX_SOS_RECIPIENTS),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const memberSnap = await membersCol(input.circleId).doc(ctx.userId).get();
      if (!memberSnap.exists) throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a member' });

      const sosId = crypto.randomUUID();
      await sosRequestsCol(input.circleId).doc(sosId).set({
        id: sosId,
        senderId: ctx.userId,
        circleId: input.circleId,
        message: input.message,
        recipientIds: input.recipientIds,
        createdAt: Timestamp.now(),
      });

      sendPushToUsers(input.recipientIds, {
        title: 'SOS Prayer Request',
        body: input.message,
        data: { circleId: input.circleId, sosId },
      }).catch(() => undefined);

      return { id: sosId, recipientCount: input.recipientIds.length };
    }),

  getRecent: protectedProcedure
    .input(
      z.object({
        circleId: z.string().optional(),
        limit: z.number().min(1).max(50).optional().default(20),
      })
    )
    .query(async ({ ctx, input }) => {
      if (input.circleId) {
        const snap = await sosRequestsCol(input.circleId)
          .orderBy('createdAt', 'desc')
          .limit(input.limit)
          .get();

        return snap.docs
          .map((d) => d.data())
          .filter((s) => (s.recipientIds as string[]).includes(ctx.userId) || s.senderId === ctx.userId)
          .map((s) => ({
            id: s.id as string,
            senderId: s.senderId as string,
            circleId: s.circleId as string,
            message: s.message as string,
            createdAt: (s.createdAt as FirebaseFirestore.Timestamp).toDate().toISOString(),
            isMine: s.senderId === ctx.userId,
          }));
      }

      // Multi-circle: get circles via collectionGroup then fetch SOS for each
      const memberSnaps = await db.collectionGroup('members').where('userId', '==', ctx.userId).get();
      const circleIds = memberSnaps.docs.map((d) => d.ref.parent.parent!.id);

      const allSOS = (
        await Promise.all(
          circleIds.map((id) =>
            sosRequestsCol(id).orderBy('createdAt', 'desc').limit(input.limit).get()
          )
        )
      ).flatMap((snap) => snap.docs.map((d) => d.data()));

      return allSOS
        .filter((s) => (s.recipientIds as string[]).includes(ctx.userId) || s.senderId === ctx.userId)
        .sort((a, b) => {
          const ta = (a.createdAt as FirebaseFirestore.Timestamp).toMillis();
          const tb = (b.createdAt as FirebaseFirestore.Timestamp).toMillis();
          return tb - ta;
        })
        .slice(0, input.limit)
        .map((s) => ({
          id: s.id as string,
          senderId: s.senderId as string,
          circleId: s.circleId as string,
          message: s.message as string,
          createdAt: (s.createdAt as FirebaseFirestore.Timestamp).toDate().toISOString(),
          isMine: s.senderId === ctx.userId,
        }));
    }),

  setSOSContacts: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        contactUserIds: z.array(z.string()).max(MAX_SOS_RECIPIENTS),
      })
    )
    .mutation(async ({ ctx, input }) => {
      await sosContactsDoc(input.circleId, ctx.userId).set({
        userId: ctx.userId,
        contactUserIds: input.contactUserIds,
        updatedAt: Timestamp.now(),
      });
      return { circleId: input.circleId, contactCount: input.contactUserIds.length };
    }),
});
