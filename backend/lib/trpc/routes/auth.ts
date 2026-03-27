import * as z from "zod";

import { createTRPCRouter, publicProcedure } from "../create-context";
import { dbGet, dbSet } from "../../lib/db";

interface UserRecord {
  id: string;
  appleUserId: string;
  email: string | null;
  displayName: string | null;
  pushToken: string | null;
}

export const authRouter = createTRPCRouter({
  signInWithApple: publicProcedure
    .input(
      z.object({
        identityToken: z.string(),
        authorizationCode: z.string(),
        fullName: z
          .object({
            givenName: z.string().nullable().optional(),
            familyName: z.string().nullable().optional(),
          })
          .nullable()
          .optional(),
        email: z.string().nullable().optional(),
      }),
    )
    .mutation(async ({ input }) => {
      const payload = decodeAppleIdentityToken(input.identityToken);

      if (!payload || !payload.sub) {
        throw new Error("Invalid Apple identity token");
      }

      const appleUserId = payload.sub;
      const email = input.email || payload.email || null;
      const displayName = [
        input.fullName?.givenName,
        input.fullName?.familyName,
      ]
        .filter(Boolean)
        .join(" ") || null;

      const user = await findOrCreateUser({
        appleUserId,
        email,
        displayName,
      });

      return {
        userId: user.id,
        displayName: user.displayName,
        isNewUser: user.isNew,
      };
    }),

  registerPushToken: publicProcedure
    .input(
      z.object({
        userId: z.string(),
        pushToken: z.string(),
      }),
    )
    .mutation(async ({ input }) => {
      const user = await dbGet<UserRecord>(`user:${input.userId}`);
      if (user) {
        user.pushToken = input.pushToken;
        await dbSet(`user:${input.userId}`, user);
      }
      await dbSet(`pushtoken:${input.userId}`, input.pushToken);
      return { success: true };
    }),
});

function decodeAppleIdentityToken(token: string): Record<string, any> | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const payload = JSON.parse(
      Buffer.from(parts[1], "base64url").toString("utf-8"),
    );
    return payload;
  } catch {
    return null;
  }
}

async function findOrCreateUser(params: {
  appleUserId: string;
  email: string | null;
  displayName: string | null;
}): Promise<UserRecord & { isNew: boolean }> {
  const existing = await dbGet<UserRecord>(`apple:${params.appleUserId}`);
  if (existing) {
    let updated = false;
    if (params.displayName && !existing.displayName) {
      existing.displayName = params.displayName;
      updated = true;
    }
    if (params.email && !existing.email) {
      existing.email = params.email;
      updated = true;
    }
    if (updated) {
      await dbSet(`apple:${params.appleUserId}`, existing);
      await dbSet(`user:${existing.id}`, existing);
    }
    return { ...existing, isNew: false };
  }

  const newUser: UserRecord = {
    id: crypto.randomUUID(),
    appleUserId: params.appleUserId,
    email: params.email,
    displayName: params.displayName,
    pushToken: null,
  };
  await dbSet(`apple:${params.appleUserId}`, newUser);
  await dbSet(`user:${newUser.id}`, newUser);
  return { ...newUser, isNew: true };
}
