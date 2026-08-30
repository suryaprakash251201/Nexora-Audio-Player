import React, { memo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import type { MusicTrack } from "@/library/types";
import { QualityBadge } from "./QualityBadge";

function sourceDot(track: MusicTrack): string {
  switch (track.source) {
    case "NEXORA_REMOTE": return "#38BDF8";
    case "DEVICE_LOCAL": return "#22C55E";
    case "NEXORA_OFFLINE": return "#F5C451";
  }
}

function formatDuration(sec: number | null): string {
  if (sec == null || !isFinite(sec)) return "—:—";
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m}:${String(s).padStart(2, "0")}`;
}

function TrackRowInner({
  track,
  onPress,
  onMore,
  active,
}: {
  track: MusicTrack;
  onPress?: () => void;
  onMore?: () => void;
  active?: boolean;
}) {
  const art = track.artwork.url;
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.root, active && styles.active, pressed && { opacity: 0.85 }]}
    >
      <View style={styles.artWrap}>
        {art ? (
          <Image source={{ uri: art }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.fallback]}>
            <Ionicons name="musical-notes" size={20} color="rgba(255,255,255,0.7)" />
          </View>
        )}
        <View style={[styles.dot, { backgroundColor: sourceDot(track) }]} />
      </View>

      <View style={styles.texts}>
        <Text numberOfLines={1} style={[styles.title, active && { color: colors.accent }]}>{track.title}</Text>
        <Text numberOfLines={1} style={styles.subtitle}>
          {[track.artist, track.album].filter(Boolean).join(" · ") || track.serverId?.path || "Unknown"}
        </Text>
        <View style={styles.metaRow}>
          <Text style={styles.meta}>{formatDuration(track.metadata.durationSec)} · {(track.metadata.codec as string) || "AUDIO"}</Text>
          <View style={{ width: 6 }} />
          <QualityBadge track={track} compact />
        </View>
      </View>

      <Pressable hitSlop={10} onPress={onMore} style={styles.moreBtn}>
        <Ionicons name="ellipsis-horizontal" size={18} color={colors.textMuted} />
      </Pressable>
    </Pressable>
  );
}

export const TrackRow = memo(TrackRowInner);

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 12,
    backgroundColor: "transparent",
  },
  active: {
    backgroundColor: "rgba(139,92,246,0.08)",
  },
  artWrap: {
    width: 52,
    height: 52,
    borderRadius: 10,
    overflow: "hidden",
    backgroundColor: "#1C1C27",
  },
  fallback: {
    backgroundColor: "#2A2A3A",
    alignItems: "center",
    justifyContent: "center",
  },
  dot: {
    position: "absolute",
    right: 4,
    bottom: 4,
    width: 8,
    height: 8,
    borderRadius: 4,
    borderWidth: 1.5,
    borderColor: "#0B0B12",
  },
  texts: { flex: 1, minWidth: 0, gap: 2 },
  title: { color: colors.text, fontSize: 14, fontWeight: "600", letterSpacing: 0.15 },
  subtitle: { color: colors.textMuted, fontSize: 12 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 4, marginTop: 2 },
  meta: { color: colors.textMuted, fontSize: 10, letterSpacing: 0.4, textTransform: "uppercase" },
  moreBtn: { width: 36, height: 36, alignItems: "center", justifyContent: "center" },
});