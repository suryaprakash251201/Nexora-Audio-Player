import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { colors, font, radius, tierColor } from "@/ui/theme";
import type { MusicTrack } from "@/library/types";

const TIER_COLOR: Record<string, string> = {
  standard: tierColor.mp3.accent,
  high: tierColor.aac.accent,
  lossless: tierColor.lossless.accent,
  hires: tierColor.hires.accent,
  dsd: tierColor.dsd.accent,
  dolby: tierColor.dolby.accent,
  spatial: tierColor.spatial.accent,
};

const TIER_LABEL: Record<string, string> = {
  standard: "MP3",
  high: "AAC",
  lossless: "LOSSLESS",
  hires: "HI-RES",
  dsd: "DSD",
  dolby: "ATMOS",
  spatial: "SPATIAL",
};

export function QualityBadge({ track, compact }: { track: MusicTrack; compact?: boolean }) {
  const q = track.metadata.quality;
  if (!q) return null;
  const tier = (q.tier as keyof typeof tierColor) ?? "mp3";
  const col = TIER_COLOR[q.tier] ?? colors.textMuted;
  const soft = (tierColor as any)[tier]?.soft ?? `${col}18`;
  const border = (tierColor as any)[tier]?.accent ? `${(tierColor as any)[tier].accent}40` : `${col}40`;
  const label = TIER_LABEL[q.tier] ?? q.codec;

  return (
    <View style={[styles.root, { borderColor: border, backgroundColor: soft }]}>
      <Text style={[styles.label, { color: col }]}>
        {compact ? label : `${label} ${q.detail ? `· ${q.detail}` : ""}`}
      </Text>
    </View>
  );
}

export function TechnicalBadge({ track }: { track: MusicTrack }) {
  const q = track.metadata.quality;
  if (!q) {
    return (
      <View style={styles.techPill}>
        <Text style={styles.techText}>AUDIO</Text>
      </View>
    );
  }

  const parts: string[] = [];
  if (q.bitDepth) parts.push(`${q.bitDepth}BIT`);
  if (q.sampleRateKHz) parts.push(`${q.sampleRateKHz}kHz`);
  parts.push(q.codec);

  const isHiRes = q.tier === "hires" || q.tier === "dsd";

  return (
    <View style={[styles.techPill, isHiRes && styles.techHiRes]}>
      <Text style={[styles.techText, isHiRes && styles.techHiResText]}>
        {parts.join(" · ")}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: radius.xs,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  label: {
    fontSize: 9,
    fontWeight: "900",
    letterSpacing: 0.8,
    fontFamily: font.sansBold,
  },
  techPill: {
    backgroundColor: "rgba(255,255,255,0.06)",
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: radius.xs,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
  },
  techHiRes: {
    backgroundColor: "rgba(251,191,36,0.14)",
    borderColor: "rgba(251,191,36,0.35)",
  },
  techText: {
    fontSize: 10,
    fontWeight: "700",
    letterSpacing: 0.6,
    color: colors.textDim,
    fontFamily: font.monoBold,
  },
  techHiResText: {
    color: "#FBBF24",
  },
});