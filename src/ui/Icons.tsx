/**
 * Curated icon set + factory. We re-export Ionicons so existing screens
 * keep working, but provide a thin, opinionated helper that:
 *  - gives every "pressable" icon a baseline size + color,
 *  - surfaces a few custom glyphs that the standard icon set doesn't have
 *    (e.g. "headphones" for audiophile brand, "speedometer" for analyzer),
 *  - and a couple of inline SVG fallbacks for high-traffic places.
 */
import React from "react";
import { Text, TextStyle, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { font } from "@/ui/theme";

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
      // Use the UI font for any system fallback glyph (so the text-equivalent
      // doesn't render in the wrong family).
      style={[{ fontFamily: font.sansRegular }, style]}
    />
  );
}

/** Tiny brand mark for the app launcher (headphones). */
export function BrandMark({ size = 28, color = "#fff" }: { size?: number; color?: string }) {
  return <Ionicons name="headset" size={size} color={color} />;
}

/** "Quality" sparkle used inside the lossless / hi-res badge. */
export function QualitySparkle({ size = 12, color = "#fff" }: { size?: number; color?: string }) {
  return <Ionicons name="sparkles" size={size} color={color} />;
}

/** "DSP" icon — re-purposed "options" glyph with a custom container. */
export function DspIcon({ size = 18, color }: { size?: number; color?: string }) {
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
      <Ionicons name="options-outline" size={size} color={color} />
      <View style={{ width: size * 0.55, height: size * 0.18, borderRadius: 2, backgroundColor: color ?? "#fff" }} />
    </View>
  );
}

/** Inline loading spinner fallback that always renders the correct font. */
export function Spinner({ color }: { color?: string }) {
  return <Text style={{ fontFamily: font.mono, color: color ?? "#fff" }}>•••</Text>;
}