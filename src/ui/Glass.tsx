import React, { ReactNode } from "react";
import { StyleProp, StyleSheet, View, ViewStyle } from "react-native";
import { BlurView } from "expo-blur";
import { LinearGradient } from "expo-linear-gradient";
import { glass as G, radius as R } from "@/ui/theme";

/**
 * GlassSurface — the single frosted-surface primitive (M25).
 *
 * Every "glassy" surface should go through this component instead of
 * hand-rolling `backgroundColor: rgba(255,255,255,0.06)` + hairline borders.
 * Before M25 that idiom was copy-pasted across ~20 call sites, so the glass
 * language could not be changed without touching every file.
 *
 * Three stacked layers:
 *   1. blur   — BlurView (CSS backdrop-filter on web)
 *   2. tint   — translucent colour that guarantees text contrast
 *   3. sheen  — specular highlight from the top-left + a 1px lit rim
 *
 * `tint="dark"` is used for the BlurView itself because the app is
 * permanently dark (see ThemeContext); the `tint` prop here is the overlay
 * colour sitting on top of the blur, controlling the perceived frosted tone.
 */
export type GlassVariant = "bar" | "card" | "sheet" | "pill" | "modal" | "neon" | "studio";

type GlassPreset = { intensity: number; tint: string; radius: number };

const PRESET: Record<GlassVariant, GlassPreset> = {
  // Bars sit over scrolling content and need the strongest, most legible glass.
  bar: { intensity: G.blur.bar, tint: G.tint.bar, radius: 0 },
  card: { intensity: G.blur.card, tint: G.tint.card, radius: R.lg },
  sheet: { intensity: G.blur.sheet, tint: G.tint.sheet, radius: R.xl },
  pill: { intensity: G.blur.subtle, tint: G.tint.pill, radius: R.pill },
  modal: { intensity: G.blur.modal, tint: G.tint.strong, radius: R.xl },
  neon: { intensity: G.blur.card, tint: "rgba(139,92,246,0.12)", radius: R.lg },
  studio: { intensity: G.blur.sheet, tint: "rgba(18,18,30,0.88)", radius: R.xl },
};

export type GlassSurfaceProps = {
  children?: ReactNode;
  variant?: GlassVariant;
  /** Blur strength (1–100). Defaults to the variant preset. */
  intensity?: number;
  /** Translucent overlay colour. Defaults to the variant preset. */
  tint?: string;
  /** Corner radius. Defaults to the variant preset. */
  radius?: number;
  /**
   * Real blur is only for surfaces that float over content (bars, sheets,
   * headers, toasts). Set `false` inside recycled lists — see GlassPanel.
   */
  blur?: boolean;
  /** Specular top-left highlight. Disable on very small controls. */
  sheen?: boolean;
  /** 1px glass rim (the lit edge that makes it read as glass). */
  border?: boolean;
  /** Neon glow border. */
  glow?: boolean;
  style?: StyleProp<ViewStyle>;
};

export function GlassSurface({
  children,
  variant = "card",
  intensity,
  tint,
  radius,
  blur = true,
  sheen = true,
  border = true,
  glow = false,
  style,
}: GlassSurfaceProps) {
  const preset = PRESET[variant];
  const r = radius ?? preset.radius;
  const i = intensity ?? preset.intensity;
  const overlay = tint ?? preset.tint;

  return (
    <View style={[styles.base, { borderRadius: r }, border && (glow ? styles.rimGlow : styles.rim), style]}>
      {blur && G.allowRealBlur ? (
        <BlurView intensity={i} tint="dark" style={StyleSheet.absoluteFill} />
      ) : null}

      {/* Tint — keeps text legible no matter what is behind the glass. */}
      <View pointerEvents="none" style={[StyleSheet.absoluteFill, { backgroundColor: overlay }]} />

      {sheen ? (
        <LinearGradient
          colors={G.sheen as unknown as [string, string, string]}
          start={{ x: 0, y: 0 }}
          end={{ x: 0.3, y: 0.85 }}
          style={StyleSheet.absoluteFill}
          pointerEvents="none"
        />
      ) : null}

      {children}
    </View>
  );
}

/**
 * GlassPanel — faux glass: tint + sheen + rim, but NO BlurView.
 *
 * A BlurView is a real GPU layer. Putting one in every FlashList row tanks
 * scroll performance, so recycled rows and grid cards use this instead. It
 * still reads as glass because over the flat app background the tint, rim and
 * sheen carry the effect — the blur is only perceptible over busy artwork,
 * which list rows do not sit on.
 */
export const GlassPanel = React.memo(function GlassPanel(props: GlassSurfaceProps) {
  return <GlassSurface {...props} blur={false} />;
});

const styles = StyleSheet.create({
  base: { overflow: "hidden", backgroundColor: "transparent" },
  rim: { borderWidth: 1, borderColor: G.edge.hairline },
  rimGlow: { borderWidth: 1, borderColor: G.edge.glow },
});
