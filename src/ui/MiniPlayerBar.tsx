import React, { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, glass, tierColor } from "@/ui/theme";
import { GlassSurface } from "@/ui/Glass";
import { usePlayback } from "@/store/PlaybackContext";
import { useDownloads } from "@/store/DownloadsContext";
import { Haptics } from "@/lib/haptics";
import QueueOverlay from "@/ui/QueueOverlay";

/**
 * MiniPlayerBar — persistent bottom bar above the tab bar.
 *
 * Modern floating design (rounded 20, glassy gradient, shadow, accent edge)
 * - insets-aware bottom offset (70pt tab + safe area)
 * - frosted BlurView backdrop (single floating bar, so real blur is cheap here;
 *   recycled list rows use GlassPanel's faux glass instead)
 * - accent left edge + rounded progress at bottom
 * - haptics, tier chip, download pill, long-press → QueueOverlay
 */
export default function MiniPlayerBar() {
  const p = usePlayback();
  const downloads = useDownloads();
  const insets = useSafeAreaInsets();
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

  const bottomOffset = 70 + Math.max(insets.bottom - 10, 0) + 8;

  return (
    <>
      <View pointerEvents="box-none" style={[s.wrap, { bottom: bottomOffset }]}>
        <Pressable onPress={onExpand} onLongPress={() => setQueueOpen(true)} style={s.root}>
          {/* Real frosted glass. The mini player is a single floating bar,
              so real blur is cheap here; rows use faux glass instead. */}
          <GlassSurface variant="bar" radius={20} style={StyleSheet.absoluteFill} />
          <View style={s.progressTrackBg}>
            <View style={[s.progressFill, { width: `${progress * 100}%`, backgroundColor: tierC.accent }]} />
          </View>
          <View style={[s.accentEdge, { backgroundColor: tierC.accent }]} />

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

          <View style={{ flex: 1, minWidth: 0, gap: 3 }}>
            <Text numberOfLines={1} style={s.title}>{cur.title}</Text>
            <View style={s.subRow}>
              <Text numberOfLines={1} style={s.sub}>{cur.artist ?? cur.album ?? "Unknown"}</Text>
              <View style={s.subBadges}>
                {dlState === "AVAILABLE_OFFLINE" ? <Ionicons name="cloud-download" size={11} color={tierC.accent} /> : null}
                {dlState === "DOWNLOADING" ? <Ionicons name="cloud-download-outline" size={11} color={tierC.accent} /> : null}
                <View style={[s.tierChip, { backgroundColor: tierC.soft, borderColor: `${tierC.accent}30`, borderWidth: 1 }]}>
                  <Text style={[s.tierLabel, { color: tierC.accent }]}>{tierC.label}</Text>
                </View>
              </View>
            </View>
          </View>

          <Pressable onPress={onToggle} hitSlop={10} style={[s.playBtn, { backgroundColor: tierC.accent }]} accessibilityLabel={p.playing ? "Pause" : "Play"}>
            <Ionicons name={p.playing ? "pause" : "play"} size={20} color="#fff" style={{ marginLeft: p.playing ? 0 : 2 }} />
          </Pressable>
          <Pressable onPress={onNext} hitSlop={10} style={s.ghost} accessibilityLabel="Next track">
            <Ionicons name="play-skip-forward" size={18} color={colors.textDim} />
          </Pressable>
          <Pressable onPress={onClose} hitSlop={10} style={s.closeBtn} accessibilityLabel="Close">
            <Ionicons name="close" size={14} color={colors.textMuted} />
          </Pressable>
        </Pressable>
      </View>
      <QueueOverlay visible={queueOpen} onClose={() => setQueueOpen(false)} />
    </>
  );
}

const s = StyleSheet.create({
  wrap: {
    position: "absolute",
    left: 12,
    right: 12,
    zIndex: 50,
  },
  root: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    backgroundColor: "transparent",
    borderRadius: 20,
    // Rim is drawn by GlassSurface; overflow keeps blur clipped to radius.
    overflow: "hidden",
    shadowColor: "#000",
    shadowOpacity: 0.45,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 12,
  },
  accentEdge: { position: "absolute", left: 0, top: 0, bottom: 0, width: 3, opacity: 0.9 },
  progressTrackBg: { position: "absolute", left: 0, right: 0, bottom: 0, height: 3, backgroundColor: "rgba(255,255,255,0.06)", overflow: "hidden" },
  progressFill: { height: 3, borderRadius: 2 },
  art: { width: 52, height: 52, borderRadius: 14, overflow: "hidden", backgroundColor: "#1C1C27", borderWidth: 1, borderColor: "rgba(255,255,255,0.10)" },
  playingDot: { position: "absolute", right: -3, bottom: -3, width: 18, height: 18, borderRadius: 9, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", borderWidth: 2, borderColor: "#1A1A26" },
  title: { color: colors.text, fontSize: 14, fontWeight: "700", fontFamily: font.sansBold, letterSpacing: 0.1 },
  subRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  sub: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular, flexShrink: 1 },
  subBadges: { flexDirection: "row", alignItems: "center", gap: 4 },
  tierChip: { paddingHorizontal: 6, paddingVertical: 2, borderRadius: 8 },
  tierLabel: { fontSize: 9, fontWeight: "800", letterSpacing: 0.6, fontFamily: font.sansBold },
  playBtn: { width: 44, height: 44, borderRadius: 22, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: "rgba(255,255,255,0.12)" },
  ghost: { width: 36, height: 36, alignItems: "center", justifyContent: "center", borderRadius: 18, backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: "rgba(255,255,255,0.06)" },
  closeBtn: { width: 28, height: 28, borderRadius: 14, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: "rgba(255,255,255,0.06)" },
});
