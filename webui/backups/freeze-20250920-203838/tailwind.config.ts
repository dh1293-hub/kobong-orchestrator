import { defineConfig } from "tailwindcss";
export default defineConfig({
  darkMode: ["class"],
  content: ["./index.html","./src/**/*.{ts,tsx,js,jsx,html}"],
  theme: {
    extend: {
      borderRadius: {
        xl: "var(--radius)",
        "2xl": "calc(var(--radius) + 8px)",
      },
      boxShadow: { glow: "0 0 0 1px hsl(220 15% 20% / 0.8), 0 10px 30px hsl(220 50% 8% / 0.4)" },
    },
  },
  safelist: [
    { pattern: /(col-span|row-span)-(1|2|3|4|5|6)/ },
    { pattern: /(bg|text|border)-(zinc|emerald|violet|red|orange|yellow|blue|purple|rose)-(200|300|400|500|600|700)/ },
    { pattern: /(justify|items)-(start|center|end|between)/ }
  ],
  plugins: [],
});