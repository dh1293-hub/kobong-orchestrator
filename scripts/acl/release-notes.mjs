#!/usr/bin/env node
import { execSync } from "node:child_process";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import process from "node:process";

const sh    = (c) => execSync(c, { encoding: "utf8" }).trim();
const trySh = (c) => { try { return sh(c); } catch { return ""; } };
const esc   = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

function latestTag() { const o = trySh("git describe --tags --abbrev=0"); return o || null; }
function tagList()   { const o = trySh("git tag --sort=-v:refname"); return o ? o.split("\n").map(s=>s.trim()).filter(Boolean) : []; }
function prevTag(curr){
  const t = tagList();
  if (!curr) return t.length>1 ? t[1] : null;
  const i = t.indexOf(curr);
  return (i>=0 && i+1<t.length) ? t[i+1] : null;
}

/** CHANGELOG에서 버전 섹션을 안전하게 추출(헤더 위치→다음 헤더 전까지 슬라이스) */
function extractFromChangelog(ver){
  try{
    const raw = readFileSync("CHANGELOG.md","utf8").replace(/\r/g,"");
    const hdr = new RegExp("^\\s*#{2,6}\\s*\\[?"+esc(ver)+"\\]?\\s*(?:\\([^)]*\\))?\\s*$","m");
    const m = hdr.exec(raw);
    if (!m) return null;

    // 헤더 한 줄 뒤부터 시작, 선행 빈줄 제거
    let rest = raw.slice(m.index + m[0].length).replace(/^\n+/, "");

    // 다음 섹션 헤더(##~######) 바로 전까지
    const nextIdx = rest.search(/^\s*#{2,6}\s/m);
    const body = nextIdx >= 0 ? rest.slice(0, nextIdx) : rest;

    return body.trim();
  } catch { return null; }
}

/** 폴백: git 로그로 노트 생성 (git 없는 tmp에서도 오류 없이 빈 결과 허용) */
function notesFromGit(prev, curr){
  let raw = "";
  if (prev) raw = trySh("git log --pretty=format:%s||%h " + prev + ".." + curr);
  else      raw = trySh("git log --pretty=format:%s||%h --max-count=200");
  const lines = raw ? raw.split("\n").filter(Boolean) : [];
  if (lines.length === 0) return "- No changes recorded.";
  return lines.map(l => {
    const parts = l.split("||");
    const s = parts[0];
    const h = parts[1];
    return "- " + s + " (" + (h ? h : "NA") + ")";
  }).join("\n");
}

function main(){
  const args  = process.argv.slice(2);
  const tagArg = (args.find(a=>a.startsWith("--tag="))||"").split("=")[1];
  const outArg = (args.find(a=>a.startsWith("--out="))||"").split("=")[1];

  const tag = tagArg || latestTag();
  if (!tag) { console.error("No git tag."); process.exit(2); }

  const ver  = tag.replace(/^v/,"");
  const prev = prevTag(tag);

  let body = extractFromChangelog(ver);         // 1차: CHANGELOG
  if (!body) body = notesFromGit(prev, tag);    // 2차: git-log 폴백

  const notes   = "# " + tag + "\n\n" + body;
  const outPath = outArg || join("out","release_notes", tag + ".md");
  const dir     = dirname(outPath);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(outPath, notes, { encoding: "utf8" });
  console.log(outPath);
}
main();