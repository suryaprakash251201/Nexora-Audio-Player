/**
 * Persistent mini player — anchored at the bottom of the stack so the
 * waveform/controls survive while the user browses albums/artists/search.
 *
 * On web the component simply is the player; on native it is the compact
 * notification area (expo-image + text + play/next/close).
 *
 * Depends on `PlaybackContext` (the queue state machine) and `NowPlayingArtwork`
 * (double-buffered image so swiping tracks never shows a blank frame).
 */
import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { usePlayback } from "@/store/PlaybackContext";
import NowPlayingArtwork from "@/ui/NowPlayingArtwork";

export default function MiniPlayer({ onExpand }: { onExpand?: () => void }) {
  const p = usePlayback();
  if (!p.current) return null;

  const track = p.current;

  return (
    <Pressable onPress={onExpand} style={styles.root}>
      <View style={styles.artWrap}>
        <NowPlayingArtwork url={track.artwork.url} trackKey={track.id} contentFit="cover" />
      </View>
      <View style={styles.texts}>
        <Text numberOfLines={1} style={styles.title}>{track.title}</Text>
        <Text numberOfLines={1} style={styles.subtitle}>{track.artist ?? "Unknown"}</Text>
      </View>
      <Pressable
        hitSlop={12}
        onPress={() => void p.toggle()}
        style={styles.playBtn}
      >
        <Ionicons name={p.playing ? "pause" : "play"} size={20} color={colors.text} />
      </Pressable>
      <Pressable hitSlop={12} onPress={() => void p.next()} style={styles.skipBtn}>
        <Ionicons name="play-skip-forward" size={20} color={colors.textDim} />
      </Pressable>
      <Pressable hitSlop={12} onPress={() => void p.close()} style={styles.closeBtn}>
        <Ionicons name="close" size={18} color={colors.textMuted} />
      </Pressable>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.bgRaised,
    borderTopWidth: 1,
    borderTopColor: colors.hairline,
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 10,
  },
  artWrap: {
    width: 44,
    height: 44,
    borderRadius: 6,
    overflow: "hidden",
    backgroundColor: colors.hairlineStrong,
  },
  texts: { flex: 1, minWidth: 0, gap: 1 },
  title: { color: colors.text, fontSize: 13, fontWeight: "600" },
  subtitle: { color: colors.textMuted, fontSize: 11 },
  playBtn: { width: 38, height: 38, borderRadius: 19, alignItems: "center", justifyContent: "center", backgroundColor: colors.bgGlass },
  skipBtn: { width: 36, height: 36, alignItems: "center", justifyContent: "center" },
  closeBtn: { width: 36, height: 36, alignItems: "center", justifyContent: "center" },
});