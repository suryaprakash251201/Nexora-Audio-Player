/**
 * Design tokens for the Nexora Audiophile client.
 *
 * Built on top of (and intentionally aligned with) the upstream Nexora theme
 * (`mobile/src/theme.ts`) so the two apps feel like siblings. The audiophile
 * player defaults to a permanent dark theme; the analyser/DSP surfaces use
 * cool, low-saturation backgrounds so loud waveforms don't blow out.
 */

export const font = {
  regular: "System",
  medium: "System",
  bold: "System",
  mono: "Menlo",
};

export const spacing = {
  xxs: 4,
  xs: 6,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
};

export const radius = {
  sm: 6,
  md: 10,
  lg: 16,
  xl: 22,
  pill: 999,
};

export const colors = {
  bg: "#0B0B12",
  bgRaised: "#13131D",
  bgGlass: "rgba(255,255,255,0.04)",
  bgGlassStrong: "rgba(20,20,32,0.78)",
  hairline: "rgba(255,255,255,0.08)",
  hairlineStrong: "rgba(255,255,255,0.16)",

  text: "#F4F4F7",
  textDim: "#C9C9D4",
  textMuted: "#7E7E8C",

  accent: "#8B5CF6",
  accentSoft: "rgba(139,92,246,0.18)",
  accentGlow: "rgba(139,92,246,0.45)",

  success: "#34D399",
  warning: "#FBBF24",
  danger: "#F87171",

  /** Spectral palette for the FFT bars. Low frequencies are warm, highs cool. */
  spectrumLow: "#F5C451",
  spectrumMid: "#8B5CF6",
  spectrumHigh: "#38BDF8",

  /** Gradient overlays used behind large artwork. */
  heroOverlay: ["rgba(11,11,18,0)", "rgba(11,11,18,0.55)", "rgba(11,11,18,0.95)"] as const,
};

export const motion = {
  fast: 160,
  base: 240,
  slow: 380,
  spring: { damping: 22, stiffness: 220, mass: 0.9 },
};

export const shadow = {
  card: {
    shadowColor: "#000",
    shadowOpacity: 0.55,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 14,
  },
};

export const gradients = {
  hero: ["rgba(139,92,246,0.25)", "rgba(11,11,18,0)"] as const,
  player: ["rgba(255,255,255,0.06)", "rgba(255,255,255,0.02)"] as const,
  danger: ["#F87171", "#B91C1C"] as const,
  aurora: ["#8B5CF6", "#38BDF8", "#34D399"] as const,
};

export type ThemeColors = typeof colors;