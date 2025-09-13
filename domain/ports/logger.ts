export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR";

export interface LogEvent {
  timestamp: string; // ISO8601
  level: LogLevel;
  traceId: string;
  module: string;
  action: string;
  inputHash?: string;
  outcome?: string;
  durationMs?: number;
  errorCode?: string;
  message: string;
  meta?: Record<string, unknown>;
}

export interface LoggerPort {
  log: (event: Omit<LogEvent, "timestamp" | "traceId"> & Partial<Pick<LogEvent, "traceId">>) => Promise<void>;
  with: (scope: { module?: string; traceId?: string }) => LoggerPort;
}
