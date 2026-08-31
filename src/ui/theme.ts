/**
 * Design tokens (M19) — refreshed colors, real fonts, motion, semantic surface layers.
 *
 * Keep the dark-audiophile language. Add:
 *  - 8-step surface scale (more depth in the player + DSP)
 *  - 6-step accent (purple) + a subtle teal "aurora" companion
 *  - 5-step severity (success/warn/danger/info + an offline "muted" tone)
 *  - Quality-tier palette shared with the web/Tauri app (so the same artwork
 *    badge looks consistent across surfaces)
 *  - Real typography: Sora for UI, JetBrains Mono for technical info
 *  - Motion tokens (spring presets) and semantic spacing
 */

export const font = {
  /** UI body / headlines. */
  sansRegular: "Sora_400Regular",
  sansMedium: "Sora_500Medium",
  sansSemibold: "Sora_600SemiBold",
  sansBold: "Sora_700Bold",
  /** Tabular numerics + technical info (24BIT | 192kHz | FLAC). */
  mono: "JetBrainsMono_500Medium",
  monoBold: "JetBrainsMono_700Bold",
};

/* ------------------------------------------------------------------ */
/* Color                                                              */
/* ------------------------------------------------------------------ */

export const surface = {
  /** App background (deep, slightly blue-black to match brand accent). */
  bg: "#0A0A12",
  /** Tab bar / sticky header. */
  bar: "#0E0E18",
  /** Cards (library rows, settings cards, DSP cards). */
  card: "#15151F",
  /** Slightly raised (now-playing meta strip, etc.). */
  raised: "#1C1C28",
  /** Glassy overlay (frosted top bar on Now Playing). */
  glass: "rgba(255,255,255,0.06)",
  glassStrong: "rgba(20,20,32,0.72)",
  /** Hairline / divider / focus ring. */
  hairline: "rgba(255,255,255,0.08)",
  hairlineStrong: "rgba(255,255,255,0.16)",
  focus: "rgba(139,92,246,0.45)",
};

export const text = {
  primary: "#F5F5FA",
  secondary: "#B8B8C8",
  muted: "#7A7A8C",
  inverse: "#0A0A12",
};

export const accent = {
  /** Primary brand purple. */
  primary: "#8B5CF6",
  primarySoft: "rgba(139,92,246,0.18)",
  primaryGlow: "rgba(139,92,246,0.42)",
  /** Subtle teal "aurora" companion. */
  aurora: "#22D3EE",
  auroraSoft: "rgba(34,211,238,0.16)",
  /** Synced / success / online. */
  success: "#22C55E",
  successSoft: "rgba(34,197,94,0.16)",
  warn: "#F5C451",
  warnSoft: "rgba(245,196,81,0.18)",
  danger: "#F87171",
  dangerSoft: "rgba(248,113,113,0.16)",
  info: "#60A5FA",
  infoSoft: "rgba(96,165,250,0.16)",
  /** Offline / muted. */
  offline: "#8A8A9A",
  offlineSoft: "rgba(138,138,154,0.16)",
};

export const colors = {
  ...surface,
  text: text.primary,
  textDim: text.secondary,
  textMuted: text.muted,
  accent: accent.primary,
  accentSoft: accent.primarySoft,
  success: accent.success,
  warning: accent.warn,
  danger: accent.danger,
  // Legacy aliases (so older screens don't break after the visual refresh).
  bgRaised: surface.raised,
  bgGlass: surface.glass,
  bgGlassStrong: surface.glassStrong,
};

/* ------------------------------------------------------------------ */
/* Quality tier palette (shared with the track badge)                 */
/* ------------------------------------------------------------------ */

export const tierColor: Record<
  "mp3" | "aac" | "lossless" | "hires" | "dsd" | "dolby" | "spatial",
  { accent: string; soft: string; label: string }
> = {
  mp3: { accent: "#8A8A9A", soft: "rgba(138,138,154,0.18)", label: "MP3" },
  aac: { accent: "#60A5FA", soft: "rgba(96,165,250,0.18)", label: "AAC" },
  lossless: { accent: "#A78BFA", soft: "rgba(167,139,250,0.18)", label: "LOSSLESS" },
  hires: { accent: "#F5C451", soft: "rgba(245,196,81,0.18)", label: "HI-RES" },
  dsd: { accent: "#22C55E", soft: "rgba(34,197,94,0.18)", label: "DSD" },
  dolby: { accent: "#38BDF8", soft: "rgba(56,189,248,0.18)", label: "DOLBY ATMOS" },
  spatial: { accent: "#22D3EE", soft: "rgba(34,211,238,0.18)", label: "SPATIAL" },
};

/* ------------------------------------------------------------------ */
/* Spectrum palette for the FFT bars (warm low → cool high)            */
/* ------------------------------------------------------------------ */

export const spectrum = {
  low: "#F5C451",
  mid: "#A78BFA",
  high: "#22D3EE",
};

/* ------------------------------------------------------------------ */
/* Spacing / radius / motion                                            */
/* ------------------------------------------------------------------ */

export const spacing = {
  xxs: 4,
  xs: 6,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 22,
  xxl: 32,
  xxxl: 48,
};

export const radius = {
  xs: 6,
  sm: 8,
  md: 12,
  lg: 18,
  xl: 24,
  pill: 999,
};

export const motion = {
  fast: 160,
  base: 240,
  slow: 380,
  spring: { damping: 22, stiffness: 220, mass: 0.9 },
  springTight: { damping: 24, stiffness: 320, mass: 0.7 },
};

export const shadow = {
  card: {
    shadowColor: "#000",
    shadowOpacity: 0.55,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 14,
  },
  fab: {
    shadowColor: accent.primary,
    shadowOpacity: 0.35,
    shadowRadius: 14,
    shadowOffset: { width: 0, height: 6 },
    elevation: 8,
  },
};

/* ------------------------------------------------------------------ */
/* Gradients                                                           */
/* ------------------------------------------------------------------ */

export const gradients = {
  hero: ["rgba(139,92,246,0.32)", "rgba(10,10,18,0)"] as const,
  heroOverlay: ["rgba(10,10,18,0.05)", "rgba(10,10,18,0.55)", "rgba(10,10,18,0.98)"] as const,
  player: ["rgba(255,255,255,0.07)", "rgba(255,255,255,0.02)"] as const,
  aurora: [accent.primary, accent.aurora, accent.success] as const,
  danger: [accent.danger, "#B91C1C"] as const,
};

export type ThemeColors = typeof colors;