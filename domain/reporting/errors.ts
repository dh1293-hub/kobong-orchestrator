/** domain/reporting/errors.ts */
export class NotImplementedError extends Error {
  constructor(msg = "Not implemented") { super(msg); this.name = "NotImplementedError"; }
}

export class ParseError extends Error {
  constructor(msg: string, public readonly position?: number) {
    super(msg); this.name = "ParseError";
  }
}
