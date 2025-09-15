/** domain/reporting/errors.ts */
export class NotImplementedError extends Error {
    constructor(msg = "Not implemented") { super(msg); this.name = "NotImplementedError"; }
}
export class ParseError extends Error {
    position;
    constructor(msg, position) {
        super(msg);
        this.position = position;
        this.name = "ParseError";
    }
}
