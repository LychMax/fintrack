// tailwind.config.js — ESM-версия (для Vite + Rolldown)
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        background: "#0f172a",
        foreground: "#e2e8f0",
        card: "#1e293b",
        "card-foreground": "#e2e8f0",
        primary: "#ec4899",        // розовый неон
        "primary-foreground": "#ffffff",
        secondary: "#a855f7",      // пурпурный
        accent: "#6366f1",
        border: "#334155",
        glass: "rgba(30, 41, 59, 0.6)",
        muted: "#64748b",
        "muted-foreground": "#94a3b8",
        destructive: "#ef4444",
      },
      borderRadius: {
        lg: "1rem",
        md: "0.75rem",
        sm: "0.5rem",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0", transform: "translateY(20px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.6s ease-out",
      },
    },
  },
  plugins: [],
};