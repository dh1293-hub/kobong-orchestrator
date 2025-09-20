import "../index.css";
import React from "react";
import { createRoot } from "react-dom/client";
import KobongGitHubOps360 from "./KobongGitHubOps360";

async function boot() {
  try {
    const res = await fetch("/ops360.json", { cache: "no-store" });
    if (res.ok) {
      (window as any).__GITHUB_DASH__ = await res.json();
    }
  } catch {}
  const root = document.getElementById("root")!;
  createRoot(root).render(<KobongGitHubOps360 />);
}
boot();