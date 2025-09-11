export class ParseError extends Error {
  lineNo: number;
  constructor(message: string, lineNo: number) {
    super(message);
    this.name = "ParseError";
    this.lineNo = lineNo;
  }
}

type Ctx = { lineNo: number; line?: string };

type ReportField = { name: string; type?: string };
export type ReportSpec = {
  version?: string;
  source?: { type: string; path?: string };
  fields?: ReportField[];
  format?: { type: string };
};

function err(ctx: Ctx, msg: string): never {
  throw new ParseError(`line ${ctx.lineNo}: ${msg} | "${ctx.line ?? ""}"`, ctx.lineNo);
}

function splitLines(input: string): string[] {
  return input
    .split(/\r?\n/)
    .map(s => s.trim())
    .filter(s => s.length > 0 && !/^#|^\/\//.test(s));
}

/** 허용 문법: "key: value" / "key=value" / "key value" */
function parseKeyValue(line: string): { key: string; value: string } | null {
  const m = line.match(/^\s*([A-Za-z][\w-]*)\s*(?::|=|\s)\s*(.+?)\s*$/);
  if (!m) return null;
  return { key: m[1].toLowerCase(), value: m[2] };
}

function parseSource(val: string): { type: string; path?: string } | null {
  const m = val.match(/^(csv)\s*[: ]\s*(.+)$/i) || val.match(/^(csv)\s+(.+)$/i);
  if (m) return { type: m[1].toLowerCase(), path: m[2].trim() };
  if (/^[A-Za-z][\w-]*$/.test(val)) return { type: val.toLowerCase() };
  return null;
}

function parseFields(val: string): ReportField[] | null {
  const items = val.split(/[,\s]+/).map(s => s.trim()).filter(Boolean);
  if (items.length === 0) return null;
  return items.map(n => ({ name: n }));
}

function parseFormat(val: string): { type: string } | null {
  const m = val.match(/^([A-Za-z][\w-]*)$/);
  if (m) return { type: m[1].toLowerCase() };
  const m2 = val.match(/^(type)\s*[:= ]\s*([A-Za-z][\w-]*)$/i);
  if (m2) return { type: m2[2].toLowerCase() };
  return null;
}

export function parseFromDsl(input: string): ReportSpec {
  if (typeof input !== "string") throw new ParseError("input must be a string DSL", 0);

  const lines = splitLines(input);
  const ctx: Ctx = { lineNo: 0 };
  const spec: ReportSpec = {};

  for (const line of lines) {
    ctx.lineNo++;
    ctx.line = line;

    const kv = parseKeyValue(line);
    if (!kv) err(ctx, "invalid syntax (expected 'key: value' / 'key=value' / 'key value')");

    switch (kv.key) {
      case "version":
        spec.version = kv.value.trim();
        break;
      case "source": {
        const src = parseSource(kv.value);
        if (!src) err(ctx, "invalid source (e.g., 'source: csv tests/fixtures/minimal.csv')");
        spec.source = src;
        break;
      }
      case "fields": {
        const fs = parseFields(kv.value);
        if (!fs) err(ctx, "invalid fields (comma/space separated)");
        spec.fields = fs;
        break;
      }
      case "format": {
        const fm = parseFormat(kv.value);
        if (!fm) err(ctx, "invalid format (e.g., 'format: table')");
        spec.format = fm;
        break;
      }
      default:
        err(ctx, `unknown key '${kv.key}'`);
    }
  }

  if (!spec.source) throw new ParseError("source 미지정", ctx.lineNo || 0);
  if (!spec.fields || spec.fields.length === 0) throw new ParseError("fields 미지정", ctx.lineNo || 0);
  if (!spec.format) throw new ParseError("format 미지정", ctx.lineNo || 0);

  return spec;
}
