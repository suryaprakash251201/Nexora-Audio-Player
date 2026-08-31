/**
 * Design tokens (M20 Redesign) — Luxury Audiophile Studio UI/UX.
 *
 * Visual Language:
 *  - Deep Obsidian Void (`#06060A`, `#0B0B12`, `#12121D`)
 *  - Electric Neon Glow (Violet `#8B5CF6`, Cyan Aurora `#06B6D4`, Gold `#F59E0B`)
 *  - Quality-tier palette: Studio Master Hi-Res Gold, Lossless Violet, DSD Emerald, Dolby Sky Blue
 *  - Typography: Sora (UI) + JetBrains Mono (Technical audio telemetry)
 *  - Tactile Motion & Elevation with Neon Sheen
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

export const textSize = {
  xs: 10,
  sm: 12,
  md: 14,
  lg: 16,
  xl: 18,
  "2xl": 22,
  "3xl": 28,
  "4xl": 36,
};

/* ------------------------------------------------------------------ */
/* Surfaces & Colors                                                  */
/* ------------------------------------------------------------------ */

export const surface = {
  /** Ultra-deep obsidian app background. */
  bg: "#06060A",
  /** Tab bar / floating dock. */
  bar: "#0B0B14",
  /** Cards & list panels. */
  card: "#12121E",
  /** Elevated cards & modal sheets. */
  raised: "#181826",
  /** Studio console surface. */
  studio: "#1A1A2B",
  /** Glassy frosted overlays. */
  glass: "rgba(255,255,255,0.05)",
  glassStrong: "rgba(18,18,30,0.85)",
  /** Borders & dividers. */
  hairline: "rgba(255,255,255,0.08)",
  hairlineStrong: "rgba(255,255,255,0.18)",
  focus: "rgba(139,92,246,0.55)",
};

export const text = {
  primary: "#FFFFFF",
  secondary: "#C4C4D4",
  muted: "#7E7E94",
  dim: "rgba(255,255,255,0.45)",
  inverse: "#06060A",
};

export const accent = {
  /** Primary brand violet. */
  primary: "#8B5CF6",
  primaryHover: "#7C3AED",
  primarySoft: "rgba(139,92,246,0.16)",
  primaryGlow: "rgba(139,92,246,0.45)",
  /** Cyan aurora companion. */
  aurora: "#06B6D4",
  auroraSoft: "rgba(6,182,212,0.16)",
  auroraGlow: "rgba(6,182,212,0.45)",
  /** Gold / Hi-Res Master. */
  gold: "#F59E0B",
  goldSoft: "rgba(245,158,11,0.18)",
  goldGlow: "rgba(245,158,11,0.45)",
  /** Success / Online / DSD Emerald. */
  success: "#10B981",
  successSoft: "rgba(16,185,129,0.16)",
  /** Warning / Alert. */
  warn: "#F59E0B",
  warnSoft: "rgba(245,158,11,0.18)",
  /** Danger / Clipping / Error. */
  danger: "#EF4444",
  dangerSoft: "rgba(239,68,68,0.16)",
  /** Info / Cloud Blue. */
  info: "#3B82F6",
  infoSoft: "rgba(59,130,246,0.16)",
  /** Offline / Muted. */
  offline: "#94A3B8",
  offlineSoft: "rgba(148,163,184,0.16)",
};

export const colors = {
  ...surface,
  text: text.primary,
  textDim: text.secondary,
  textMuted: text.muted,
  accent: accent.primary,
  accentSoft: accent.primarySoft,
  accentGlow: accent.primaryGlow,
  success: accent.success,
  warning: accent.warn,
  danger: accent.danger,
  // Legacy aliases
  bgRaised: surface.raised,
  bgGlass: surface.glass,
  bgGlassStrong: surface.glassStrong,
  interactive: accent.primary,
  disabled: "rgba(255,255,255,0.12)",
  placeholder: text.muted,
};

/* ------------------------------------------------------------------ */
/* Quality Tier Palette                                               */
/* ------------------------------------------------------------------ */

export const tierColor: Record<
  "mp3" | "aac" | "lossless" | "hires" | "dsd" | "dolby" | "spatial",
  { accent: string; soft: string; label: string; glow: string }
> = {
  mp3: { accent: "#94A3B8", soft: "rgba(148,163,184,0.16)", glow: "rgba(148,163,184,0.3)", label: "MP3" },
  aac: { accent: "#38BDF8", soft: "rgba(56,189,248,0.16)", glow: "rgba(56,189,248,0.35)", label: "AAC" },
  lossless: { accent: "#A78BFA", soft: "rgba(167,139,250,0.18)", glow: "rgba(167,139,250,0.45)", label: "LOSSLESS" },
  hires: { accent: "#FBBF24", soft: "rgba(251,191,36,0.20)", glow: "rgba(251,191,36,0.5)", label: "HI-RES" },
  dsd: { accent: "#10B981", soft: "rgba(16,185,129,0.18)", glow: "rgba(16,185,129,0.45)", label: "DSD" },
  dolby: { accent: "#60A5FA", soft: "rgba(96,165,250,0.18)", glow: "rgba(96,165,250,0.4)", label: "DOLBY ATMOS" },
  spatial: { accent: "#06B6D4", soft: "rgba(6,182,212,0.18)", glow: "rgba(6,182,212,0.45)", label: "SPATIAL" },
};

/* ------------------------------------------------------------------ */
/* Spectrum Palette for FFT Bars                                      */
/* ------------------------------------------------------------------ */

export const spectrum = {
  low: "#F59E0B",
  mid: "#8B5CF6",
  high: "#06B6D4",
};

/* ------------------------------------------------------------------ */
/* Spacing / Radius / Motion                                          */
/* ------------------------------------------------------------------ */

export const spacing = {
  xxs: 4,
  xs: 6,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 28,
  xxxl: 40,
};

export const radius = {
  xs: 6,
  sm: 8,
  md: 12,
  lg: 18,
  xl: 24,
  xxl: 32,
  pill: 999,
};

export const motion = {
  fast: 150,
  base: 240,
  slow: 360,
  spring: { damping: 20, stiffness: 240, mass: 0.8 },
  springTight: { damping: 24, stiffness: 340, mass: 0.6 },
  springSnappy: { damping: 26, stiffness: 420, mass: 0.5 },
  springBouncy: { damping: 14, stiffness: 200, mass: 0.9 },
  springGentle: { damping: 22, stiffness: 140, mass: 1.0 },
};

/* ------------------------------------------------------------------ */
/* Elevation & Shadows                                                */
/* ------------------------------------------------------------------ */

export const shadow = {
  sm: {
    shadowColor: "#000",
    shadowOpacity: 0.35,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 4,
  },
  md: {
    shadowColor: "#000",
    shadowOpacity: 0.5,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 4 },
    elevation: 8,
  },
  lg: {
    shadowColor: "#000",
    shadowOpacity: 0.65,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 14,
  },
  xl: {
    shadowColor: "#000",
    shadowOpacity: 0.8,
    shadowRadius: 32,
    shadowOffset: { width: 0, height: 12 },
    elevation: 20,
  },
  glow: (color: string, opacity = 0.4) => ({
    shadowColor: color,
    shadowOpacity: opacity,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 6 },
    elevation: 10,
  }),
  card: {
    shadowColor: "#000",
    shadowOpacity: 0.6,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 6 },
    elevation: 12,
  },
  fab: {
    shadowColor: accent.primary,
    shadowOpacity: 0.45,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 6 },
    elevation: 10,
  },
};

/* ------------------------------------------------------------------ */
/* Gradients                                                          */
/* ------------------------------------------------------------------ */

export const gradients = {
  hero: ["rgba(139,92,246,0.35)", "rgba(6,182,212,0.12)", "rgba(6,6,10,0)"] as const,
  heroOverlay: ["rgba(6,6,10,0.02)", "rgba(6,6,10,0.6)", "rgba(6,6,10,0.98)"] as const,
  player: ["rgba(255,255,255,0.08)", "rgba(255,255,255,0.02)"] as const,
  aurora: [accent.primary, accent.aurora, accent.success] as const,
  goldHiRes: ["#F59E0B", "#D97706", "#78350F"] as const,
  vinyl: ["#1F1F2E", "#0A0A12", "#181828", "#07070D"] as const,
  danger: [accent.danger, "#B91C1C"] as const,
};

/* ------------------------------------------------------------------ */
/* Glassmorphism System                                               */
/* ------------------------------------------------------------------ */

export const glass = {
  blur: {
    subtle: 16,
    card: 28,
    bar: 50,
    sheet: 64,
    modal: 80,
  },
  tint: {
    bar: "rgba(11,11,20,0.68)",
    card: "rgba(255,255,255,0.04)",
    sheet: "rgba(14,14,26,0.82)",
    pill: "rgba(255,255,255,0.08)",
    strong: "rgba(16,16,28,0.90)",
    scrim: "rgba(6,6,10,0.60)",
  },
  edge: {
    top: "rgba(255,255,255,0.18)",
    bottom: "rgba(255,255,255,0.03)",
    hairline: "rgba(255,255,255,0.10)",
    strong: "rgba(255,255,255,0.22)",
    glow: "rgba(139,92,246,0.30)",
  },
  sheen: ["rgba(255,255,255,0.12)", "rgba(255,255,255,0.03)", "rgba(255,255,255,0)"] as const,
  allowRealBlur: true,
};

export type ThemeColors = typeof colors;