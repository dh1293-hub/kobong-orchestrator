import React, { useState } from "react";

type EBProps = { onError: (e: Error) => void; children?: React.ReactNode };
type EBState = { hasError: boolean };

/** Dev-friendly ErrorBoundary (TS-safe) */
export function ErrorBoundary({ children }: { children?: React.ReactNode }) {
  const [, setErr] = useState<Error | null>(null);
  return <EB onError={(e: Error) => setErr(e)}>{children}</EB>;
}
export default ErrorBoundary;

class EB extends React.Component<EBProps, EBState> {
  state: EBState = { hasError: false };
  static getDerivedStateFromError(_err: Error): EBState { return { hasError: true }; }
  componentDidCatch(error: Error, _info: React.ErrorInfo) {
    try { this.props.onError?.(error); } catch {}
  }
  render() { return this.state.hasError ? null : (this.props.children as React.ReactNode); }
}