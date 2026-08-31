import React, { memo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import type { MusicTrack } from "@/library/types";
import { QualityBadge } from "./QualityBadge";
import { PlayingIndicator } from "./PlayingIndicator";

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

function folderFromPath(path?: string | null): string | null {
  if (!path) return null;
  const idx = path.lastIndexOf("/");
  if (idx <= 0) return "/";
  const folder = path.slice(0, idx);
  // show only last 2 segments for brevity: e.g. "FLAC / Artist"
  const segs = folder.split("/").filter(Boolean);
  if (segs.length <= 2) return folder;
  return segs.slice(-2).join(" / ");
}

function TrackRowInner({
  track,
  onPress,
  onMore,
  active,
  downloadState,
  downloadProgress,
}: {
  track: MusicTrack;
  onPress?: () => void;
  onMore?: () => void;
  active?: boolean;
  downloadState?: "REMOTE" | "DOWNLOADING" | "AVAILABLE_OFFLINE" | "FAILED";
  downloadProgress?: number;
}) {
  const art = track.artwork.url;
  const folder = folderFromPath(track.serverId?.path);
  // Prefer artist+album, else folder path, else raw path
  const subtitlePrimary = [track.artist, track.album].filter(Boolean).join(" · ");
  const subtitle = subtitlePrimary || folder || track.serverId?.path || "Unknown";
  const showFolderHint = !subtitlePrimary && !!folder && folder !== "/";
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
        {active ? (
          <View style={styles.playingOverlay}>
            <PlayingIndicator playing={true} color="#fff" size={16} />
          </View>
        ) : null}
      </View>

      <View style={styles.texts}>
        <Text numberOfLines={1} style={[styles.title, active && { color: colors.accent }]}>{track.title}</Text>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
          <Text numberOfLines={1} style={[styles.subtitle, { flexShrink: 1 }]}>
            {subtitle}
          </Text>
          {showFolderHint ? (
            <View style={styles.folderChip}>
              <Ionicons name="folder-outline" size={10} color={colors.textMuted} />
              <Text numberOfLines={1} style={styles.folderChipText}>{track.serverId?.path.split("/").pop()}</Text>
            </View>
          ) : null}
        </View>
        <View style={styles.metaRow}>
          <Text style={styles.meta}>{formatDuration(track.metadata.durationSec)} · {(track.metadata.codec as string) || "AUDIO"}</Text>
          {track.serverId?.rootId ? (
            <View style={styles.rootChip}>
              <Text style={styles.rootChipText}>{track.serverId.rootId.slice(0, 6)}</Text>
            </View>
          ) : null}
          <View style={{ width: 6 }} />
          <QualityBadge track={track} compact />
          {downloadState === "AVAILABLE_OFFLINE" ? <Ionicons name="download" size={12} color="#22C55E" /> : null}
          {downloadState === "DOWNLOADING" ? <Ionicons name="sync" size={12} color="#F5C451" /> : null}
          {downloadState === "FAILED" ? <Ionicons name="alert-circle" size={12} color="#F87171" /> : null}
          {downloadState === "DOWNLOADING" && typeof downloadProgress === "number" ? (
            <Text style={[styles.meta, { color: "#F5C451" }]}>{Math.round(downloadProgress * 100)}%</Text>
          ) : null}
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
  folderChip: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    paddingHorizontal: 6,
    height: 18,
    borderRadius: 9,
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    maxWidth: 110,
  },
  folderChipText: { color: colors.textMuted, fontSize: 10, fontWeight: "600" },
  rootChip: {
    paddingHorizontal: 5,
    height: 16,
    borderRadius: 4,
    backgroundColor: "rgba(56,189,248,0.12)",
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.22)",
    alignItems: "center",
    justifyContent: "center",
  },
  rootChipText: { color: "#38BDF8", fontSize: 9, fontWeight: "800", letterSpacing: 0.5 },
  playingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(139,92,246,0.65)",
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 10,
  },
});