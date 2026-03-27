import { createTRPCRouter } from "./create-context";
import { authRouter } from "./routes/auth";
import { circlesRouter } from "./routes/circles";
import { inviteRouter } from "./routes/invite";
import { gratitudesRouter } from "./routes/gratitudes";
import { sosRouter } from "./routes/sos";
import { userRouter } from "./routes/user";

export const appRouter = createTRPCRouter({
  auth: authRouter,
  user: userRouter,
  circles: circlesRouter,
  sos: sosRouter,
  invite: inviteRouter,
  gratitudes: gratitudesRouter,
});

export type AppRouter = typeof appRouter;
