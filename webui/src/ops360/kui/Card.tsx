import * as React from "react";
export function Card({ title, subtitle, actions, className = "", children }: {
  title?: React.ReactNode; subtitle?: React.ReactNode; actions?: React.ReactNode; className?: string; children?: React.ReactNode;
}) {
  return (
    <section className={"rounded-2xl p-4 bg-white/5 backdrop-blur border border-white/10 shadow-sm hover:shadow-md transition-shadow " + className}>
      <header className="flex items-center justify-between mb-3">
        <div>
          {title && <h3 className="text-sm font-semibold text-white/90">{title}</h3>}
          {subtitle && <p className="text-xs text-white/60">{subtitle}</p>}
        </div>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </header>
      <div className="min-h-[60px]">{children}</div>
    </section>
  );
}