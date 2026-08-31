/**
 * Curated Audiophile Icon Set & Studio Glyphs.
 */
import React from "react";
import { StyleSheet, Text, TextStyle, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { font, accent, tierColor } from "@/ui/theme";

export type IconName = keyof typeof Ionicons.glyphMap;

const DEFAULT_SIZE = 22;

type IconProps = {
  name: IconName;
  size?: number;
  color?: string;
  strokeWidth?: number;
  style?: TextStyle;
};

export function Icon({ name, size = DEFAULT_SIZE, color, style }: IconProps) {
  return (
    <Ionicons
      name={name}
      size={size}
      color={color}
      style={[{ fontFamily: font.sansRegular }, style]}
    />
  );
}

/** Brand mark with neon glow aura (headphones). */
export function BrandMark({ size = 28, color = "#fff" }: { size?: number; color?: string }) {
  return (
    <View style={styles.brandMark}>
      <Ionicons name="headset" size={size} color={color} />
    </View>
  );
}

/** Quality sparkle badge. */
export function QualitySparkle({ size = 12, color = "#fff" }: { size?: number; color?: string }) {
  return <Ionicons name="sparkles" size={size} color={color} />;
}

/** Studio DSP icon with equalizing sliders representation. */
export function DspIcon({ size = 18, color = accent.primary }: { size?: number; color?: string }) {
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 3 }}>
      <Ionicons name="options-outline" size={size} color={color} />
      <View style={{ width: 4, height: 10, borderRadius: 2, backgroundColor: color }} />
    </View>
  );
}

/** Vinyl record disc glyph. */
export function VinylRecordIcon({ size = 24, color = "#fff" }: { size?: number; color?: string }) {
  const r = size / 2;
  return (
    <View style={[styles.vinylOuter, { width: size, height: size, borderRadius: r, borderColor: color }]}>
      <View style={[styles.vinylGroove, { width: size * 0.65, height: size * 0.65, borderRadius: r * 0.65, borderColor: color }]} />
      <View style={[styles.vinylCenter, { width: size * 0.28, height: size * 0.28, borderRadius: r * 0.28, backgroundColor: accent.primary }]} />
    </View>
  );
}

/** Hi-Res Gold Studio Master icon. */
export function HiResGoldEmblem({ size = 18 }: { size?: number }) {
  return (
    <View style={[styles.hiResPill, { paddingHorizontal: size * 0.35, height: size }]}>
      <Text style={[styles.hiResText, { fontSize: Math.max(8, size * 0.52) }]}>HI-RES</Text>
    </View>
  );
}

/** Spatial 360 audio icon. */
export function SpatialAudioIcon({ size = 20, color = accent.aurora }: { size?: number; color?: string }) {
  return (
    <View style={{ width: size, height: size, alignItems: "center", justifyContent: "center" }}>
      <Ionicons name="radio-outline" size={size} color={color} />
      <View style={{ position: "absolute", width: 4, height: 4, borderRadius: 2, backgroundColor: color }} />
    </View>
  );
}

/** Inline loading spinner fallback that always renders the correct font. */
export function Spinner({ color }: { color?: string }) {
  return <Text style={{ fontFamily: font.mono, color: color ?? "#fff" }}>•••</Text>;
}

const styles = StyleSheet.create({
  brandMark: {
    alignItems: "center",
    justifyContent: "center",
  },
  vinylOuter: {
    borderWidth: 1.5,
    alignItems: "center",
    justifyContent: "center",
    opacity: 0.9,
  },
  vinylGroove: {
    position: "absolute",
    borderWidth: 1,
    opacity: 0.4,
  },
  vinylCenter: {
    position: "absolute",
  },
  hiResPill: {
    backgroundColor: tierColor.hires.soft,
    borderWidth: 1,
    borderColor: tierColor.hires.accent,
    borderRadius: 4,
    alignItems: "center",
    justifyContent: "center",
  },
  hiResText: {
    color: tierColor.hires.accent,
    fontFamily: font.sansBold,
    fontWeight: "900",
    letterSpacing: 0.5,
  },
});