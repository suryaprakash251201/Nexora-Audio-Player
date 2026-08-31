import React, { useMemo } from "react";
import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors, font, spacing, tierColor } from "@/ui/theme";
import { useLayout } from "@/ui/layout";
import { useLibrary } from "@/store/LibraryContext";
import { useSession } from "@/store/SessionContext";
import { usePlayback } from "@/store/PlaybackContext";
import { groupByAlbum, groupByArtist, groupByFolder, getFolderName, getFolderPath } from "@/library/nexora";
import { Section } from "@/ui/Section";
import { EmptyState } from "@/ui/EmptyState";
import { ConnectBanner } from "@/ui/ConnectBanner";
import { TrackRow } from "@/ui/TrackRow";
import { AlbumCard, ArtistCard, FolderCard } from "@/ui/AlbumCard";
import { StatsRow } from "@/ui/StatsRow";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { Toast } from "@/ui/Toast";
import type { MusicTrack } from "@/library/types";

function getGreeting(): string {
  const h = new Date().getHours();
  if (h < 5) return "Good night";
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  if (h < 21) return "Good evening";
  return "Good night";
}

export default function HomeScreen() {
  const { tracks, bySource, counts, loading, refresh } = useLibrary();
  const { api, user } = useSession();
  const playback = usePlayback();
  const { albumColumns, isTablet } = useLayout();

  const recents = useMemo(
    () => [...tracks].sort((a, b) => Date.parse(b.modifiedAt || "0") - Date.parse(a.modifiedAt || "0")).slice(0, 8),
    [tracks],
  );

  const albums = useMemo(() => {
    const m = groupByAlbum(tracks);
    return [...m.entries()].filter(([k]) => k !== "__singles__").sort((a, b) => b[1].length - a[1].length).slice(0, isTablet ? 12 : 8);
  }, [tracks, isTablet]);

  const artists = useMemo(() => {
    const m = groupByArtist(tracks);
    return [...m.entries()].sort((a, b) => b[1].length - a[1].length).slice(0, isTablet ? 8 : 6);
  }, [tracks, isTablet]);

  const folders = useMemo(() => {
    const m = groupByFolder(tracks);
    return [...m.entries()].sort((a, b) => b[1].length - a[1].length).slice(0, isTablet ? 8 : 6);
  }, [tracks, isTablet]);

  const onPlay = (t: MusicTrack, list: MusicTrack[]) => {
    void playback.play(t, list);
    Toast.show(`Now playing · ${t.title}`, "info", { icon: "play", duration: 1500 });
  };

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Welcome"
        title={user ? `${getGreeting()}, ${user.username}` : getGreeting()}
        subtitle={`${counts.unified.toLocaleString()} tracks across Nexora, device and offline`}
        right={
          <View style={{ flexDirection: "row", gap: 8 }}>
            <View style={styles.headerDot} />
          </View>
        }
      />

      <ScrollView
        contentContainerStyle={{ paddingBottom: 120, gap: spacing.lg }}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={() => void refresh()} tintColor={colors.text} />}
      >
        <View style={{ paddingHorizontal: spacing.lg, gap: spacing.md }}>
          <StatsRow
            nexora={counts.nexora}
            device={counts.device}
            offline={counts.offline}
            refreshing={loading}
            onRefresh={() => void refresh()}
          />
        </View>

        {!api ? (
          <View style={{ paddingHorizontal: spacing.lg }}>
            <ConnectBanner />
          </View>
        ) : null}

        {tracks.length === 0 && !loading ? (
          <EmptyState
            title={api ? "No music found" : "Welcome to Nexora Audiophile"}
            subtitle={api
              ? "Your Nexora search for kind=audio returned no files. Add audio to your roots and pull to refresh."
              : "Connect to your Nexora server to stream FLAC, ALAC, WAV and DSD. On-device tracks appear automatically."}
            action={api ? { label: "Refresh", onPress: () => void refresh() } : { label: "Connect to Nexora", onPress: () => router.push("/login") }}
          />
        ) : null}

        {recents.length ? (
          <Section title="Recently added" count={recents.length} action={{ label: "See all", onPress: () => router.push("/(tabs)/library") }}>
            <View>
              {recents.slice(0, 5).map((t) => (
                <TrackRow
                  key={t.id}
                  track={t}
                  onPress={() => onPlay(t, recents)}
                  active={playback.current?.id === t.id}
                />
              ))}
            </View>
          </Section>
        ) : null}

        {albums.length ? (
          <Section title="Albums" count={albums.length}>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={{ paddingHorizontal: spacing.lg, gap: spacing.md }}
            >
              {albums.map(([name, list]) => {
                const w = albumColumns === 2 ? 200 : albumColumns >= 4 ? 168 : 180;
                const sub = name.split(" — ")[1] || "Various Artists";
                return (
                  <AlbumCard
                    key={name}
                    title={name.split(" — ")[0]}
                    subtitle={sub}
                    count={list.length}
                    cover={list[0]?.artwork.url ?? null}
                    width={w}
                    onPress={() => onPlay(list[0], list)}
                  />
                );
              })}
            </ScrollView>
          </Section>
        ) : null}

        {artists.length ? (
          <Section title="Artists" count={artists.length}>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={{ paddingHorizontal: spacing.lg, gap: spacing.md }}
            >
              {artists.map(([name, list], i) => (
                <ArtistCard
                  key={name}
                  name={name}
                  count={list.length}
                  cover={list[0]?.artwork.url ?? null}
                  onPress={() => onPlay(list[0], list)}
                  size={i === 0 ? 168 : 132}
                />
              ))}
            </ScrollView>
          </Section>
        ) : null}

        {folders.length ? (
          <Section title="Folders" count={folders.length} subtitle="Browse by directory · cover from first track">
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={{ paddingHorizontal: spacing.lg, gap: spacing.md }}
            >
              {folders.map(([key, list]) => {
                const w = albumColumns === 2 ? 200 : albumColumns >= 4 ? 168 : 180;
                const sep = key.indexOf(":");
                const rawPath = sep >= 0 ? key.slice(sep + 1) : key;
                const name = getFolderName(rawPath);
                const fullFolder = rawPath;
                return (
                  <FolderCard
                    key={key}
                    name={name}
                    path={fullFolder}
                    count={list.length}
                    cover={list[0]?.artwork.url ?? null}
                    width={w}
                    onPress={() => onPlay(list[0], list)}
                  />
                );
              })}
            </ScrollView>
          </Section>
        ) : null}

        <View style={{ paddingHorizontal: spacing.lg, gap: spacing.md }}>
          <View style={styles.card}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
              <View style={styles.cardIcon}>
                <Ionicons name="library-outline" size={20} color={colors.accent} />
              </View>
              <View style={{ flex: 1, gap: 2 }}>
                <Text style={styles.cardTitle}>Library structure</Text>
                <Text style={styles.cardBody}>Nexora · On Device · Downloads · Favorites · Recently Played · Playlists</Text>
              </View>
            </View>
            <View style={styles.cardRow}>
              <Tile onPress={() => router.push("/(tabs)/library")} icon="folder" label="Open Library" />
              <Tile onPress={() => router.push("/(tabs)/playlists")} icon="list" label="Playlists" />
              <Tile onPress={() => router.push("/(tabs)/search")} icon="search" label="Search" />
            </View>
          </View>
        </View>
      </ScrollView>
    </Container>
  );
}

function Tile({ icon, label, onPress }: { icon: keyof typeof Ionicons.glyphMap; label: string; onPress: () => void }) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => ({
        flex: 1,
        alignItems: "center",
        justifyContent: "center",
        paddingVertical: 10,
        borderRadius: 12,
        backgroundColor: pressed ? "rgba(255,255,255,0.08)" : "rgba(255,255,255,0.04)",
        borderWidth: 1,
        borderColor: colors.hairline,
        gap: 4,
      })}
      accessibilityRole="button"
      accessibilityLabel={label}
    >
      <Ionicons name={icon} size={16} color={colors.text} />
      <Text style={{ color: colors.text, fontSize: 11, fontFamily: font.sansSemibold }}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerDot: { width: 12, height: 12, borderRadius: 6, backgroundColor: tierColor.hires.accent, shadowColor: tierColor.hires.accent, shadowOpacity: 0.6, shadowRadius: 6, shadowOffset: { width: 0, height: 0 } },
  card: { backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, borderRadius: 16, padding: 16, gap: 12 },
  cardIcon: { width: 40, height: 40, borderRadius: 12, backgroundColor: "rgba(139,92,246,0.16)", alignItems: "center", justifyContent: "center" },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 14, fontFamily: font.sansBold },
  cardBody: { color: colors.textMuted, fontSize: 12, lineHeight: 16, fontFamily: font.sansRegular },
  cardRow: { flexDirection: "row", gap: 8 },
});