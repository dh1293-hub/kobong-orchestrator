import { HttpClientPort, HttpRequest, HttpResponse } from "../../../domain/ports/httpClient";
import { createJsonlLogger } from "../../logging/jsonlLogger";

const log = createJsonlLogger({ defaultModule: "infra.stub.http" }).with({ module: "infra.stub.http" });

export class StubHttpClient implements HttpClientPort {
  async send<T = unknown>(req: HttpRequest): Promise<HttpResponse<T>> {
    await log.log({
      module: "infra.stub.http",
      level: "DEBUG",
      action: "http.send.stub",
      message: "Stub HTTP client called",
      meta: { input: req }
    });
    return {
      status: 501,
      headers: {},
      data: { error: "Not implemented" } as unknown as T
    };
  }
}

