/** Quiet stderr filter: hide "fatal: not a git repository" lines during tests */
const origWrite = process.stderr.write.bind(process.stderr);
process.stderr.write = (chunk, enc, cb) => {
  try {
    const text = typeof chunk === "string" ? chunk : Buffer.from(chunk).toString(enc || "utf8");
    if (/^fatal: not a git repository/mi.test(text)) return true; // swallow
  } catch {/* ignore */}
  // @ts-expect-error node typings overload
  return origWrite(chunk, enc, cb);
};
