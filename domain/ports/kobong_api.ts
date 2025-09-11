export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

export interface KobongRequest {
  url: string;
  method?: HttpMethod;
  headers?: Record<string, string>;
  /** Raw string payload (usually JSON string). */
  data?: string | null;
  timeoutMs?: number;
}

export interface KobongSuccess {
  ok: true;
  bodyText: string;
  json?: unknown;
}

export interface KobongFailure {
  ok: false;
  status?: number;
  statusText?: string;
  bodyText: string;
}

export type KobongResponse = KobongSuccess | KobongFailure;

export interface KobongApiPort {
  request(req: KobongRequest): Promise<KobongResponse>;
}