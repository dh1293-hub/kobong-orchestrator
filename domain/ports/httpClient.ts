export interface HttpRequest {
  url: string;
  method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  headers?: Record<string, string>;
  body?: unknown;
  timeoutMs?: number;
}

export interface HttpResponse<T = unknown> {
  status: number;
  headers: Record<string, string | string[]>;
  data: T;
}

export interface HttpClientPort {
  send: <T = unknown>(req: HttpRequest) => Promise<HttpResponse<T>>;
}
