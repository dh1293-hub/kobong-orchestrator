import React from "react";

export default function Sparkline({ data, width=300, height=48, stroke="#0a66ff", strokeWidth=1.5 }: {
  data: number[]; width?: number; height?: number; stroke?: string; strokeWidth?: number;
}) {
  if (!data || data.length === 0) return null;
  const min = Math.min(...data);
  const max = Math.max(...data);
  const pad = 2;
  const W = width, H = height;
  const xs = data.map((_, i) => (i / (data.length - 1)) * (W - pad*2) + pad);
  const ys = data.map(v => {
    if (max === min) return H/2;
    const t = (v - min) / (max - min);
    return (1 - t) * (H - pad*2) + pad;
  });
  const d = xs.map((x, i) => `${i===0?'M':'L'}${x.toFixed(1)},${ys[i].toFixed(1)}`).join(" ");
  return (
    <svg width="100%" height={H} viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" role="img" aria-label="sparkline">
      <path d={d} fill="none" stroke={stroke} strokeWidth={strokeWidth} strokeLinejoin="round" strokeLinecap="round" />
    </svg>
  );
}
