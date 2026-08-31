import React, { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, { useAnimatedStyle, useSharedValue, withSpring, withTiming } from "react-native-reanimated";
import { router, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import NowPlayingArtwork from "@/ui/NowPlayingArtwork";
import { WaveformSeekBar } from "@/ui/Waveform";
import { TechnicalBadge } from "@/ui/QualityBadge";
import { SpectrumBars } from "@/ui/Spectrum";
import QueueOverlay from "@/ui/QueueOverlay";
import { Haptics } from "@/lib/haptics";

function fmtTime(sec: number): string {
  if (!sec || !isFinite(sec)) return "0:00";
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m}:${String(s).padStart(2, "0")}`;
}

export default function NowPlayingScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const decoded = id ? decodeURIComponent(String(id)) : "";
  const lib = useLibrary();
  const playback = usePlayback();
  const insets = useSafeAreaInsets();

  const [showSpectrum, setShowSpectrum] = useState(false);
  const [showQueue, setShowQueue] = useState(false);
  const dragY = useSharedValue(0);
  const dragOpacity = useSharedValue(1);

  const current = playback.current || (decoded ? lib.tracks.find((t) => t.id === decoded) || null : null);
  const track = current;

  const progress = useMemo(() => {
    if (!playback.duration) return 0;
    return Math.max(0, Math.min(1, playback.currentTime / playback.duration));
  }, [playback.currentTime, playback.duration]);

  const onSeekRatio = (ratio: number) => {
    const dur = playback.duration || track?.metadata.durationSec || 0;
    if (!dur) return;
    void playback.seekTo(ratio * dur);
  };

  // Swipe down to dismiss — only when the ScrollView is scrolled to the top.
  const pan = Gesture.Pan()
    .activeOffsetY(-12)
    .onUpdate((e) => {
      if (e.translationY > 0) {
        dragY.value = Math.max(0, e.translationY);
        dragOpacity.value = withTiming(Math.max(0.35, 1 - e.translationY / 560), { duration: 80 });
      }
    })
    .onEnd((e) => {
      if (e.translationY > 140 && e.velocityY > 400) {
        dragY.value = withSpring(600, { damping: 18, stiffness: 220 });
        dragOpacity.value = withTiming(0, { duration: 180 });
        Haptics.tapMedium();
        setTimeout(() => router.back(), 160);
      } else {
        dragY.value = withSpring(0, { damping: 20, stiffness: 260 });
        dragOpacity.value = withTiming(1, { duration: 200 });
      }
    });

  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: dragY.value }],
    opacity: dragOpacity.value,
  }));

  if (!track) {
    return (
      <View style={[styles.root, { paddingTop: insets.top + 12 }]}>
        <Pressable onPress={() => router.back()} style={styles.topBack}>
          <Ionicons name="chevron-down" size={22} color={colors.text} />
          <Text style={styles.topTitle}>Now Playing</Text>
        </Pressable>
        <View style={styles.empty}>
          <Text style={styles.emptyTitle}>Nothing playing</Text>
          <Text style={styles.emptyBody}>Pick a track from Home, Library or a playlist.</Text>
        </View>
      </View>
    );
  }

  const isShuffle = playback.shuffle;
  const repeat = playback.repeat;

  return (
    <View style={styles.root}>
      {/* Immersive background — blurred artwork + gradient scrim */}
      <View style={StyleSheet.absoluteFill}>
        {track.artwork.url ? (
          <Image source={{ uri: track.artwork.url }} style={StyleSheet.absoluteFill} contentFit="cover" blurRadius={28} cachePolicy="memory-disk" />
        ) : (
          <LinearGradient colors={["#1C2650", "#0B0B12"]} style={StyleSheet.absoluteFill} />
        )}
        <LinearGradient colors={["rgba(11,11,18,0.15)", "rgba(11,11,18,0.55)", "rgba(11,11,18,0.98)"]} style={StyleSheet.absoluteFill} />
      </View>

      <GestureDetector gesture={pan}>
        <Animated.View style={[{ flex: 1, paddingTop: insets.top + 6, paddingBottom: insets.bottom + 10 }, sheetStyle]}>
          {/* Top bar */}
          <View style={styles.topBar}>
            <Pressable onPress={() => router.back()} hitSlop={12} style={styles.topBtn} accessibilityLabel="Dismiss">
              <Ionicons name="chevron-down" size={22} color="#fff" />
            </Pressable>
            <View style={{ alignItems: "center", gap: 2 }}>
              <Text style={styles.nowPlaying}>NOW PLAYING</Text>
              <Text style={styles.nowSource}>{track.source === "NEXORA_REMOTE" ? "Nexora" : track.source === "NEXORA_OFFLINE" ? "Downloaded" : "On Device"} · {track.album || "Single"}</Text>
            </View>
            <Pressable onPress={() => router.push("/info/[id]" as any)} hitSlop={12} style={styles.topBtn} accessibilityLabel="Track info">
              <Ionicons name="ellipsis-horizontal" size={18} color="rgba(255,255,255,0.9)" />
            </Pressable>
          </View>

          <ScrollView contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 12, gap: 14 }} showsVerticalScrollIndicator={false}>
            {/* Large artwork — double-buffered, never blank between swipes */}
            <View style={styles.artCard}>
              <NowPlayingArtwork url={track.artwork.url} trackKey={track.id} contentFit="cover" />
              <View style={styles.losslessBadge}>
                <Ionicons name="radio-outline" size={12} color="#fff" />
                <Text style={styles.losslessLabel}>{track.metadata.quality?.tier === "hires" ? "HI-RES" : track.metadata.quality?.tier === "lossless" ? "LOSSLESS" : track.metadata.quality?.label || track.metadata.codec as string}</Text>
              </View>
            </View>

            {/* Title / artist / album */}
            <View style={{ gap: 4 }}>
              <View style={styles.titleRow}>
                <Text numberOfLines={2} style={styles.title}>{track.title}</Text>
                <Ionicons name={track.favorite ? "heart" : "heart-outline"} size={20} color={track.favorite ? "#F87171" : "rgba(255,255,255,0.85)"} />
              </View>
              <Text numberOfLines={1} style={styles.artist}>{track.artist || "Unknown artist"}</Text>
              {track.album ? <Text numberOfLines={1} style={styles.album}>{track.album}</Text> : null}
            </View>

            {/* Waveform / seek */}
            <View style={{ gap: 6 }}>
              <Pressable onPress={() => setShowSpectrum((v) => !v)}>
                <WaveformSeekBar
                  progress={progress}
                  duration={playback.duration || track.metadata.durationSec || 0}
                  seed={track.id}
                  onSeek={onSeekRatio}
                />
                <Text style={styles.waveHint}>
                  Tap waveform to {showSpectrum ? "hide" : "show"} spectrum · tap bar to seek
                </Text>
              </Pressable>
              <View style={styles.timeRow}>
                <Text style={styles.time}>{fmtTime(playback.currentTime)}</Text>
                <TechnicalBadge track={track} />
                <Text style={styles.time}>{fmtTime(playback.duration || track.metadata.durationSec || 0)}</Text>
              </View>
              {showSpectrum ? (
                <View style={styles.spectrumBox}>
                  <SpectrumBars seed={track.id} estimated barCount={32} />
                </View>
              ) : null}
            </View>

            {/* Main controls */}
            <View style={styles.controls}>
              <Pressable onPress={() => { Haptics.tapLight(); playback.setShuffle(!isShuffle); }} style={[styles.ctrlGhost, isShuffle && styles.ctrlActive]}>
                <Ionicons name="shuffle" size={20} color={isShuffle ? colors.accent : "rgba(255,255,255,0.9)"} />
              </Pressable>
              <Pressable onPress={() => { Haptics.tapLight(); void playback.prev(); }} style={styles.ctrlBig}>
                <Ionicons name="play-skip-back" size={26} color="#fff" />
              </Pressable>
              <Pressable onPress={() => { Haptics.tapLight(); void playback.toggle(); }} style={styles.playBtn}>
                <Ionicons name={playback.playing ? "pause" : "play"} size={32} color="#fff" style={{ marginLeft: playback.playing ? 0 : 2 }} />
              </Pressable>
              <Pressable onPress={() => { Haptics.tapLight(); void playback.next(); }} style={styles.ctrlBig}>
                <Ionicons name="play-skip-forward" size={26} color="#fff" />
              </Pressable>
              <Pressable
                onPress={() => {
                  Haptics.tapLight();
                  const next = repeat === "off" ? "all" : repeat === "all" ? "one" : "off";
                  playback.setRepeat(next);
                }}
                style={[styles.ctrlGhost, repeat !== "off" && styles.ctrlActive]}
              >
                <Ionicons name={repeat === "one" ? "repeat" : "repeat"} size={20} color={repeat !== "off" ? colors.accent : "rgba(255,255,255,0.9)"} />
                {repeat === "one" ? <Text style={styles.repeatOne}>1</Text> : null}
              </Pressable>
            </View>

            {/* Bottom actions */}
            <View style={styles.bottomRow}>
              <Pressable onPress={() => router.push("/dsp" as any)} style={styles.bottomAction}>
                <Ionicons name="options-outline" size={18} color="rgba(255,255,255,0.9)" />
                <Text style={styles.bottomLabel}>Studio DSP</Text>
              </Pressable>
              <Pressable onPress={() => router.push("/info/[id]" as any)} style={styles.bottomAction}>
                <Ionicons name="information-circle-outline" size={18} color="rgba(255,255,255,0.9)" />
                <Text style={styles.bottomLabel}>Audio Info</Text>
              </Pressable>
              <Pressable onPress={() => { Haptics.tapLight(); setShowQueue(true); }} style={styles.bottomAction}>
                <Ionicons name="list-outline" size={18} color="rgba(255,255,255,0.9)" />
                <Text style={styles.bottomLabel}>Queue · {playback.queue.length}</Text>
              </Pressable>
            </View>
          </ScrollView>
        </Animated.View>
      </GestureDetector>

      <QueueOverlay visible={showQueue} onClose={() => setShowQueue(false)} />
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#0B0B12" },
  topBack: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 16 },
  topTitle: { color: colors.text, fontWeight: "800", fontSize: 14 },
  empty: { flex: 1, alignItems: "center", justifyContent: "center", gap: 8, padding: 24 },
  emptyTitle: { color: colors.text, fontWeight: "800", fontSize: 16 },
  emptyBody: { color: colors.textMuted, fontSize: 13, textAlign: "center" },
  topBar: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 12, paddingBottom: 8 },
  topBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: "rgba(255,255,255,0.10)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: "rgba(255,255,255,0.12)" },
  nowPlaying: { color: "rgba(255,255,255,0.85)", fontSize: 11, fontWeight: "800", letterSpacing: 1.2, fontFamily: font.sansBold },
  nowSource: { color: "rgba(255,255,255,0.65)", fontSize: 11, fontFamily: font.sansRegular },
  artCard: { height: 340, borderRadius: 20, overflow: "hidden", backgroundColor: "#16161F", borderWidth: 1, borderColor: "rgba(255,255,255,0.10)" },
  losslessBadge: { position: "absolute", top: 12, left: 12, flexDirection: "row", gap: 6, alignItems: "center", backgroundColor: "rgba(0,0,0,0.38)", borderWidth: 1, borderColor: "rgba(255,255,255,0.16)", paddingHorizontal: 10, height: 26, borderRadius: 13 },
  losslessLabel: { color: "#fff", fontSize: 10, fontWeight: "800", letterSpacing: 0.6, fontFamily: font.sansBold },
  titleRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: 10 },
  title: { flex: 1, color: "#fff", fontSize: 20, fontWeight: "800", letterSpacing: -0.3, lineHeight: 22, fontFamily: font.sansBold },
  artist: { color: "rgba(255,255,255,0.85)", fontSize: 14, fontWeight: "600", fontFamily: font.sansSemibold },
  album: { color: "rgba(255,255,255,0.6)", fontSize: 12, fontFamily: font.sansRegular },
  waveHint: { color: "rgba(255,255,255,0.45)", fontSize: 10, textAlign: "center", marginTop: 2, fontFamily: font.sansRegular },
  spectrumBox: { backgroundColor: "rgba(255,255,255,0.04)", borderRadius: 12, padding: 10, borderWidth: 1, borderColor: "rgba(255,255,255,0.06)" },
  timeRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  time: { color: "rgba(255,255,255,0.7)", fontSize: 11, fontWeight: "600", fontVariant: ["tabular-nums"] as any, fontFamily: font.sansSemibold },
  controls: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingTop: 8 },
  ctrlGhost: { width: 44, height: 44, borderRadius: 22, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(255,255,255,0.08)", borderWidth: 1, borderColor: "rgba(255,255,255,0.10)", position: "relative" },
  ctrlActive: { backgroundColor: "rgba(139,92,246,0.18)", borderColor: "rgba(139,92,246,0.35)" },
  ctrlBig: { width: 54, height: 54, borderRadius: 27, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(255,255,255,0.08)", borderWidth: 1, borderColor: "rgba(255,255,255,0.10)" },
  playBtn: { width: 68, height: 68, borderRadius: 34, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", shadowColor: colors.accent, shadowOpacity: 0.35, shadowRadius: 12, elevation: 8 },
  repeatOne: { position: "absolute", right: 6, top: 6, color: colors.accent, fontSize: 9, fontWeight: "800" },
  bottomRow: { flexDirection: "row", gap: 10, justifyContent: "space-between", paddingTop: 4 },
  bottomAction: { flex: 1, flexDirection: "row", gap: 6, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(255,255,255,0.07)", borderWidth: 1, borderColor: "rgba(255,255,255,0.10)", height: 40, borderRadius: 12 },
  bottomLabel: { color: "rgba(255,255,255,0.9)", fontSize: 12, fontWeight: "700", fontFamily: font.sansSemibold },
});
