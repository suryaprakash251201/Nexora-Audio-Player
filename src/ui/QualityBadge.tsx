import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { colors } from "@/ui/theme";
import type { MusicTrack } from "@/library/types";

const TIER_COLOR: Record<string, string> = {
  standard: colors.textMuted,
  high: "#4EA1FF",
  lossless: "#8B5CF6",
  hires: "#F5C451",
  dsd: "#22C55E",
  dolby: "#38BDF8",
  spatial: "#06B6D4",
};

const TIER_LABEL: Record<string, string> = {
  standard: "MP3",
  high: "AAC",
  lossless: "LOSSLESS",
  hires: "HI-RES",
  dsd: "DSD",
  dolby: "DOLBY ATMOS",
  spatial: "SPATIAL",
};

export function QualityBadge({ track, compact }: { track: MusicTrack; compact?: boolean }) {
  const q = track.metadata.quality;
  if (!q) return null;
  const bg = TIER_COLOR[q.tier] ?? colors.textMuted;
  const label = TIER_LABEL[q.tier] ?? q.codec;
  return (
    <View style={[styles.root, { borderColor: bg, backgroundColor: `${bg}14` }]}>
      <Text style={[styles.label, { color: bg }]}>{compact ? label : `${label} · ${q.detail ?? q.codec}`}</Text>
    </View>
  );
}

export function TechnicalBadge({ track }: { track: MusicTrack }) {
  const q = track.metadata.quality;
  if (!q) return (
    <Text style={styles.tech}>AUDIO</Text>
  );
  const parts: string[] = [];
  if (q.bitDepth) parts.push(`${q.bitDepth}BIT`);
  if (q.sampleRateKHz) parts.push(`${q.sampleRateKHz}kHz`);
  parts.push(q.codec);
  return <Text style={styles.tech}>{parts.join(" | ")}</Text>;
}

const styles = StyleSheet.create({
  root: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  label: { fontSize: 9, fontWeight: "800", letterSpacing: 0.6 },
  tech: { fontSize: 10, fontWeight: "700", letterSpacing: 0.5, color: colors.textMuted },
});