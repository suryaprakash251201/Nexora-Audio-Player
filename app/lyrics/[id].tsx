import React, { useEffect, useMemo, useRef, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, spacing } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { usePlayback } from "@/store/PlaybackContext";
import { useLibrary } from "@/store/LibraryContext";
import type { LyricCue } from "@/api/types";

export default function LyricsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const decoded = id ? decodeURIComponent(String(id)) : "";
  const { api } = useSession();
  const playback = usePlayback();
  const lib = useLibrary();
  const insets = useSafeAreaInsets();

  const track = playback.current || (decoded ? lib.tracks.find((t) => t.id === decoded) || null : null);

  const [cues, setCues] = useState<LyricCue[]>([]);
  const [raw, setRaw] = useState("");
  const [synced, setSynced] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<ScrollView>(null);
  const lineRefs = useRef<Record<number, number>>({});

  useEffect(() => {
    if (!api || !track?.serverId) {
      setLoading(false);
      setError("Not connected or no track selected");
      return;
    }
    setLoading(true);
    setError(null);
    api.getLyrics(track.serverId.rootId, track.serverId.path)
      .then((res) => {
        if (res.has_lyrics) {
          setCues(res.cues || []);
          setRaw(res.raw || "");
          setSynced(res.synced);
        } else {
          setCues([]);
          setRaw("");
          setSynced(false);
          setError("No lyrics found for this track");
        }
      })
      .catch((e: any) => setError(e?.message || "Failed to load lyrics"))
      .finally(() => setLoading(false));
  }, [api, track?.id, track?.serverId]);

  const activeLine = useMemo(() => {
    if (!synced || !cues.length) return -1;
    const t = playback.currentTime;
    for (let i = cues.length - 1; i >= 0; i--) {
      if (cues[i].time <= t) return i;
    }
    return -1;
  }, [synced, cues, playback.currentTime]);

  useEffect(() => {
    if (activeLine >= 0 && synced) {
      const y = lineRefs.current[activeLine];
      if (y !== undefined && scrollRef.current) {
        scrollRef.current.scrollTo({ y: Math.max(0, y - 200), animated: true });
      }
    }
  }, [activeLine, synced]);

  return (
    <View style={[styles.root, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <Pressable onPress={() => router.back()} style={styles.iconBtn}>
          <Ionicons name="close" size={18} color={colors.text} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>LYRICS</Text>
          <Text style={styles.sub} numberOfLines={1}>
            {track?.title ?? "No track"} {track?.artist ? `· ${track.artist}` : ""}
          </Text>
        </View>
        {synced ? (
          <View style={styles.syncBadge}>
            <Ionicons name="time-outline" size={12} color="#22C55E" />
            <Text style={styles.syncLabel}>Synced</Text>
          </View>
        ) : cues.length ? (
          <View style={[styles.syncBadge, { borderColor: colors.hairline }]}>
            <Text style={[styles.syncLabel, { color: colors.textMuted }]}>Plain</Text>
          </View>
        ) : null}
      </View>

      {loading ? (
        <View style={styles.center}>
          <Text style={styles.centerText}>Loading lyrics…</Text>
        </View>
      ) : error && !cues.length ? (
        <View style={styles.center}>
          <Ionicons name="text-outline" size={40} color={colors.textMuted} />
          <Text style={styles.centerTitle}>No lyrics</Text>
          <Text style={styles.centerText}>{error}</Text>
        </View>
      ) : (
        <ScrollView
          ref={scrollRef}
          contentContainerStyle={{ padding: spacing.lg, paddingBottom: insets.bottom + 120 }}
          showsVerticalScrollIndicator={false}
        >
          {synced && cues.length ? (
            cues.map((cue, i) => (
              <Pressable
                key={i}
                onPress={() => void playback.seekTo(cue.time)}
                onLayout={(e) => { lineRefs.current[i] = e.nativeEvent.layout.y; }}
                style={styles.line}
              >
                <Text
                  style={[
                    styles.lyricText,
                    i === activeLine && styles.lyricActive,
                    i < activeLine && styles.lyricPast,
                  ]}
                >
                  {cue.text || "♪"}
                </Text>
              </Pressable>
            ))
          ) : (
            <Text style={styles.plainText}>{raw || "No lyrics available"}</Text>
          )}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  header: { flexDirection: "row", gap: 10, alignItems: "center", paddingHorizontal: 16, paddingBottom: 10 },
  iconBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  title: { color: colors.text, fontSize: 14, fontWeight: "900", letterSpacing: 1.2, fontFamily: font.sansBold },
  sub: { color: colors.textMuted, fontSize: 11, lineHeight: 13, marginTop: 2, fontFamily: font.sansRegular },
  syncBadge: { flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 8, height: 24, borderRadius: 12, borderWidth: 1, borderColor: "rgba(34,197,94,0.32)", backgroundColor: "rgba(34,197,94,0.12)" },
  syncLabel: { color: "#22C55E", fontSize: 10, fontWeight: "800", fontFamily: font.sansBold },
  center: { flex: 1, alignItems: "center", justifyContent: "center", gap: 10, padding: 24 },
  centerTitle: { color: colors.text, fontWeight: "800", fontSize: 18, fontFamily: font.sansBold },
  centerText: { color: colors.textMuted, fontSize: 13, textAlign: "center", fontFamily: font.sansRegular },
  line: { paddingVertical: 8 },
  lyricText: { color: "rgba(255,255,255,0.4)", fontSize: 22, fontWeight: "700", lineHeight: 30, fontFamily: font.sansBold, letterSpacing: -0.3 },
  lyricActive: { color: "#fff", fontSize: 24 },
  lyricPast: { color: "rgba(255,255,255,0.25)" },
  plainText: { color: colors.textDim, fontSize: 16, lineHeight: 28, fontFamily: font.sansRegular },
});
