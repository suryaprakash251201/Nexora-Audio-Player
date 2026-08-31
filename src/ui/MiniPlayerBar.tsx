import React, { useState } from "react";
import { Animated, Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors, font, radius, spacing, tierColor } from "@/ui/theme";
import { usePlayback } from "@/store/PlaybackContext";
import { useDownloads } from "@/store/DownloadsContext";
import { Haptics } from "@/lib/haptics";
import QueueOverlay from "@/ui/QueueOverlay";

/**
 * MiniPlayerBar — persistent bottom bar above the tab bar.
 *
 * M20 polish:
 *  - real fonts, refined radii, subtle progress bar behind the artwork
 *  - download status pill (offline/syncing/downloaded) shows next to the title
 *  - long-press → QueueOverlay (with swipe-to-remove)
 *  - haptics on every action
 */
export default function MiniPlayerBar() {
  const p = usePlayback();
  const downloads = useDownloads();
  const [queueOpen, setQueueOpen] = useState(false);
  const cur = p.current;
  if (!cur) return null;

  const dlState = downloads.stateByTrackId[cur.id] || (cur.source === "NEXORA_OFFLINE" ? "AVAILABLE_OFFLINE" : undefined);
  const tier = cur.metadata.quality?.tier ?? "standard";
  const tierC = (tierColor as any)[tier] ?? tierColor.mp3;
  const progress = p.duration ? Math.max(0, Math.min(1, p.currentTime / p.duration)) : 0;

  const onExpand = () => {
    Haptics.tapLight();
    router.push({ pathname: "/track/[id]", params: { id: encodeURIComponent(cur.id) } });
  };
  const onToggle = () => {
    Haptics.tapLight();
    void p.toggle();
  };
  const onNext = () => {
    Haptics.selection();
    void p.next();
  };
  const onClose = () => {
    Haptics.tapMedium();
    void p.close();
  };

  return (
    <>
      <Pressable onPress={onExpand} onLongPress={() => setQueueOpen(true)} style={s.root}>
        {/* progress strip behind everything */}
        <View style={s.progressTrack}>
          <View style={[s.progressFill, { width: `${progress * 100}%`, backgroundColor: tierC.accent }]} />
        </View>

        <View style={s.art}>
          {cur.artwork.url ? (
            <Image source={{ uri: cur.artwork.url }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
          ) : (
            <View style={[StyleSheet.absoluteFill, { backgroundColor: "#1E1E2A", alignItems: "center", justifyContent: "center" }]}>
              <Ionicons name="musical-notes" size={16} color="rgba(255,255,255,0.7)" />
            </View>
          )}
          {p.playing ? (
            <View style={s.playingDot}>
              <Ionicons name="musical-note" size={9} color="#fff" />
            </View>
          ) : null}
        </View>

        <View style={{ flex: 1, minWidth: 0, gap: 2 }}>
          <Text numberOfLines={1} style={s.title}>{cur.title}</Text>
          <View style={s.subRow}>
            <Text numberOfLines={1} style={s.sub}>{cur.artist ?? cur.album ?? "Unknown"}</Text>
            <View style={s.subBadges}>
              {dlState === "AVAILABLE_OFFLINE" ? <Ionicons name="cloud-download" size={11} color={tierC.accent} /> : null}
              {dlState === "DOWNLOADING" ? <Ionicons name="cloud-download-outline" size={11} color={tierC.accent} /> : null}
              <View style={[s.tierChip, { backgroundColor: tierC.soft }]}>
                <Text style={[s.tierLabel, { color: tierC.accent }]}>{tierC.label}</Text>
              </View>
            </View>
          </View>
        </View>

        <Pressable onPress={onToggle} hitSlop={10} style={s.playBtn} accessibilityLabel={p.playing ? "Pause" : "Play"}>
          <Ionicons name={p.playing ? "pause" : "play"} size={20} color={colors.text} />
        </Pressable>
        <Pressable onPress={onNext} hitSlop={10} style={s.ghost} accessibilityLabel="Next track">
          <Ionicons name="play-skip-forward" size={18} color={colors.textDim} />
        </Pressable>
      </Pressable>
      <QueueOverlay visible={queueOpen} onClose={() => setQueueOpen(false)} />
    </>
  );
}

const s = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingHorizontal: 12,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: colors.card,
    borderTopWidth: 1,
    borderTopColor: colors.hairline,
    overflow: "hidden",
  },
  progressTrack: { position: "absolute", left: 0, right: 0, top: 0, height: 2, backgroundColor: "rgba(255,255,255,0.06)" },
  progressFill: { height: 2 },
  art: { width: 46, height: 46, borderRadius: radius.sm, overflow: "hidden", backgroundColor: "#1C1C27" },
  playingDot: { position: "absolute", right: -3, bottom: -3, width: 16, height: 16, borderRadius: 8, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", borderWidth: 2, borderColor: colors.card },
  title: { color: colors.text, fontSize: 13, fontWeight: "700", fontFamily: font.sansBold },
  subRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  sub: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular, flexShrink: 1 },
  subBadges: { flexDirection: "row", alignItems: "center", gap: 4 },
  tierChip: { paddingHorizontal: 5, paddingVertical: 1, borderRadius: 4 },
  tierLabel: { fontSize: 9, fontWeight: "800", letterSpacing: 0.6, fontFamily: font.sansBold },
  playBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: "rgba(255,255,255,0.08)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  ghost: { width: 36, height: 36, alignItems: "center", justifyContent: "center" },
});