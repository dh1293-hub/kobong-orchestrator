import { z } from "zod";

export const LogEvent = z.object({
  timestamp: z.string().min(1),
  level: z.enum(["DEBUG","INFO","WARN","ERROR"]),
  traceId: z.string().min(1),
  module: z.string().min(1),
  action: z.string().min(1),
  inputHash: z.string().min(1),
  outcome: z.string().min(1),
  durationMs: z.number().int().nonnegative(),
  errorCode: z.string().optional(),
  message: z.string()
});
export type LogEvent = z.infer<typeof LogEvent>;