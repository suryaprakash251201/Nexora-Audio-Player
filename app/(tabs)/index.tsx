import React, { useMemo } from "react";
import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { useSession } from "@/store/SessionContext";
import { usePlayback } from "@/store/PlaybackContext";
import { groupByAlbum, groupByArtist } from "@/library/nexora";
import { Section } from "@/ui/Section";
import { EmptyState } from "@/ui/EmptyState";
import { ConnectBanner } from "@/ui/ConnectBanner";
import { TrackRow } from "@/ui/TrackRow";
import type { MusicTrack } from "@/library/types";

function AlbumCard({ title, count, cover, onPress }: { title: string; count: number; cover: string | null; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.albumCard}>
      <View style={styles.albumArt}>
        {cover ? <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" /> : <LinearGradient colors={["#1C2650", "#5B8CFF"]} style={StyleSheet.absoluteFill} />}
        <View style={styles.albumShade} />
        <Text numberOfLines={2} style={styles.albumTitle}>{title}</Text>
        <Text style={styles.albumCount}>{count} tracks</Text>
      </View>
    </Pressable>
  );
}

export default function HomeScreen() {
  const { tracks, bySource, counts, loading, refresh } = useLibrary();
  const { api, user } = useSession();
  const playback = usePlayback();

  const recents = useMemo(() => [...tracks].sort((a, b) => Date.parse(b.modifiedAt || "0") - Date.parse(a.modifiedAt || "0")).slice(0, 8), [tracks]);
  const albums = useMemo(() => {
    const m = groupByAlbum(tracks);
    const entries = [...m.entries()].filter(([k]) => k !== "__singles__").sort((a, b) => b[1].length - a[1].length).slice(0, 8);
    return entries;
  }, [tracks]);
  const artists = useMemo(() => {
    const m = groupByArtist(tracks);
    return [...m.entries()].sort((a, b) => b[1].length - a[1].length).slice(0, 10);
  }, [tracks]);

  const onPlay = (t: MusicTrack, list: MusicTrack[]) => { void playback.play(t, list); };

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <ScrollView
        refreshControl={<RefreshControl refreshing={loading} onRefresh={() => void refresh()} tintColor={colors.text} />}
        contentContainerStyle={{ paddingBottom: 28 }}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.greeting}>Good evening{user?.username ? `, ${user.username}` : ""}</Text>
            <Text style={styles.sub}>Your music · {counts.unified} tracks</Text>
          </View>
          <Pressable onPress={() => router.push("/(tabs)/search")} style={styles.searchBtn}>
            <Ionicons name="search" size={18} color={colors.textDim} />
          </Pressable>
        </View>

        {/* Library stats strip */}
        <View style={styles.statsRow}>
          <View style={styles.stat}>
            <Text style={styles.statNum}>{counts.nexora}</Text>
            <Text style={styles.statLabel}>Nexora</Text>
            <View style={[styles.statDot, { backgroundColor: "#38BDF8" }]} />
          </View>
          <View style={styles.stat}>
            <Text style={styles.statNum}>{counts.device}</Text>
            <Text style={styles.statLabel}>On Device</Text>
            <View style={[styles.statDot, { backgroundColor: "#22C55E" }]} />
          </View>
          <View style={styles.stat}>
            <Text style={styles.statNum}>{counts.offline}</Text>
            <Text style={styles.statLabel}>Offline</Text>
            <View style={[styles.statDot, { backgroundColor: "#F5C451" }]} />
          </View>
          <Pressable onPress={() => void refresh()} style={styles.refreshBtn}>
            <Ionicons name="refresh" size={16} color={colors.textMuted} />
          </Pressable>
        </View>

        {!api ? <ConnectBanner /> : null}

        {tracks.length === 0 && !loading ? (
          <EmptyState
            title={api ? "No music found" : "Connect to see your library"}
            subtitle={api ? "Your Nexora search for kind=audio returned no files. Add audio to your roots and pull to refresh." : "Once connected, your library, albums, artists and playlists appear here. On-device tracks appear automatically when you grant permission."}
            action={api ? { label: "Refresh", onPress: () => void refresh() } : { label: "Connect to Nexora", onPress: () => router.push("/login") }}
          />
        ) : null}

        {/* Recently added */}
        {recents.length ? (
          <Section title="Recently added" count={recents.length} action={{ label: "See all", onPress: () => router.push("/(tabs)/library") }}>
            <View>
              {recents.slice(0, 5).map((t) => (
                <TrackRow key={t.id} track={t} onPress={() => onPlay(t, recents)} active={playback.current?.id === t.id} />
              ))}
            </View>
          </Section>
        ) : null}

        {/* Albums */}
        {albums.length ? (
          <Section title="Albums" count={albums.length}>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, gap: 12 }}>
              {albums.map(([name, list]) => (
                <AlbumCard key={name} title={name.split(" — ")[0]} count={list.length} cover={list[0]?.artwork.url ?? null} onPress={() => onPlay(list[0], list)} />
              ))}
            </ScrollView>
          </Section>
        ) : null}

        {/* Artists */}
        {artists.length ? (
          <Section title="Artists" count={artists.length}>
            <View style={{ paddingHorizontal: 16, gap: 8 }}>
              {artists.slice(0, 6).map(([name, list]) => (
                <Pressable key={name} onPress={() => onPlay(list[0], list)} style={styles.artistRow}>
                  <View style={styles.artistArt}>
                    {list[0]?.artwork.url ? <Image source={{ uri: list[0].artwork.url! }} style={StyleSheet.absoluteFill} contentFit="cover" /> : <LinearGradient colors={["#2A2A3A", "#444"] as const} style={StyleSheet.absoluteFill} />}
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text numberOfLines={1} style={styles.artistName}>{name}</Text>
                    <Text style={styles.artistMeta}>{list.length} tracks</Text>
                  </View>
                  <Ionicons name="play-circle" size={22} color={colors.textMuted} />
                </Pressable>
              ))}
            </View>
          </Section>
        ) : null}

        {/* Library structure teaser */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Library structure</Text>
          <Text style={styles.cardBody}>Library → Nexora · On Device · Downloads · Favorites · Recently Played · Playlists. Use the Library tab to filter by source. Downloads arrive in M4.</Text>
          <Pressable onPress={() => router.push("/(tabs)/library")} style={styles.cardBtn}>
            <Text style={styles.cardBtnLabel}>Open Library</Text>
          </Pressable>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 16, paddingTop: 14, paddingBottom: 8 },
  greeting: { color: colors.text, fontSize: 20, fontWeight: "800", letterSpacing: -0.3 },
  sub: { color: colors.textMuted, fontSize: 12, marginTop: 2 },
  searchBtn: { width: 38, height: 38, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  statsRow: { flexDirection: "row", gap: 10, paddingHorizontal: 16, paddingVertical: 10, alignItems: "center" },
  stat: { flex: 1, backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, padding: 12, gap: 4 },
  statNum: { color: colors.text, fontSize: 20, fontWeight: "800" },
  statLabel: { color: colors.textMuted, fontSize: 11, fontWeight: "700", letterSpacing: 0.4, textTransform: "uppercase" },
  statDot: { position: "absolute", right: 10, top: 10, width: 8, height: 8, borderRadius: 4 },
  refreshBtn: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, alignItems: "center", justifyContent: "center" },
  albumCard: { width: 128 },
  albumArt: { height: 128, borderRadius: 12, overflow: "hidden", backgroundColor: "#16161F", justifyContent: "flex-end", padding: 10 },
  albumShade: { ...StyleSheet.absoluteFillObject, backgroundColor: "rgba(0,0,0,0.22)" },
  albumTitle: { color: "#fff", fontWeight: "800", fontSize: 12, lineHeight: 14 },
  albumCount: { color: "rgba(255,255,255,0.75)", fontSize: 10, marginTop: 2 },
  artistRow: { flexDirection: "row", alignItems: "center", gap: 12, backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, padding: 10 },
  artistArt: { width: 44, height: 44, borderRadius: 10, overflow: "hidden", backgroundColor: "#1E1E2A" },
  artistName: { color: colors.text, fontWeight: "700", fontSize: 13 },
  artistMeta: { color: colors.textMuted, fontSize: 11, marginTop: 1 },
  card: { margin: 16, backgroundColor: colors.bgRaised, borderRadius: 14, padding: 16, borderWidth: 1, borderColor: colors.hairline, gap: 8 },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 14 },
  cardBody: { color: colors.textMuted, fontSize: 12, lineHeight: 16 },
  cardBtn: { alignSelf: "flex-start", marginTop: 6, backgroundColor: colors.accent, paddingHorizontal: 14, paddingVertical: 8, borderRadius: 8 },
  cardBtnLabel: { color: "#fff", fontWeight: "800", fontSize: 12 },
});