import React, { useMemo } from "react";
import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors, font, spacing, tierColor, accent, radius, shadow } from "@/ui/theme";
import { useLayout } from "@/ui/layout";
import { useLibrary } from "@/store/LibraryContext";
import { useSession } from "@/store/SessionContext";
import { usePlayback } from "@/store/PlaybackContext";
import { groupByAlbum, groupByArtist, groupByFolder, getFolderName } from "@/library/nexora";
import { Section } from "@/ui/Section";
import { EmptyState } from "@/ui/EmptyState";
import { ConnectBanner } from "@/ui/ConnectBanner";
import { TrackRow } from "@/ui/TrackRow";
import { AlbumCard, ArtistCard, FolderCard } from "@/ui/AlbumCard";
import { StatsRow } from "@/ui/StatsRow";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { Toast } from "@/ui/Toast";
import { Haptics } from "@/lib/haptics";
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
  const { tracks, counts, loading, refresh } = useLibrary();
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

  const onShuffleAll = () => {
    if (!tracks.length) return;
    Haptics.tapMedium();
    const shuffled = [...tracks].sort(() => Math.random() - 0.5);
    playback.setShuffle(true);
    void playback.play(shuffled[0], shuffled);
    Toast.success("Shuffling all tracks");
  };

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Audiophile Studio"
        title={user ? `${getGreeting()}, ${user.username}` : getGreeting()}
        subtitle={`${counts.unified.toLocaleString()} master tracks ready for playback`}
        right={
          <View style={styles.headerBadge}>
            <View style={styles.headerDot} />
            <Text style={styles.headerBadgeText}>DAC 192k</Text>
          </View>
        }
      />

      <ScrollView
        contentContainerStyle={{ paddingBottom: 130, gap: spacing.lg }}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={() => void refresh()} tintColor={accent.primary} />}
      >
        {/* Quick Shuffle Hero Banner */}
        {tracks.length > 0 ? (
          <View style={{ paddingHorizontal: spacing.lg }}>
            <LinearGradient
              colors={["#2E1065", "#1E1B4B", "#0F172A"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.heroBanner}
            >
              <View style={styles.heroContent}>
                <View style={styles.heroTag}>
                  <Ionicons name="sparkles" size={12} color="#FBBF24" />
                  <Text style={styles.heroTagText}>STUDIO MASTER ENGINE</Text>
                </View>
                <Text style={styles.heroTitle}>Lossless Audio Vault</Text>
                <Text style={styles.heroSub}>
                  Bit-perfect decoding · 10-band studio DSP equalizer · Synced lyrics
                </Text>
              </View>

              <View style={styles.heroActions}>
                <Pressable
                  onPress={onShuffleAll}
                  style={({ pressed }) => [styles.heroBtn, pressed && { opacity: 0.85, transform: [{ scale: 0.97 }] }]}
                >
                  <Ionicons name="shuffle" size={16} color="#fff" />
                  <Text style={styles.heroBtnText}>Shuffle All</Text>
                </Pressable>
                <Pressable
                  onPress={() => router.push("/dsp" as any)}
                  style={({ pressed }) => [styles.heroBtnGhost, pressed && { opacity: 0.75 }]}
                >
                  <Ionicons name="options-outline" size={16} color="#C4C4D4" />
                  <Text style={styles.heroBtnGhostText}>Studio DSP</Text>
                </Pressable>
              </View>
            </LinearGradient>
          </View>
        ) : null}

        {/* Telemetry Stats HUD */}
        <View style={{ paddingHorizontal: spacing.lg }}>
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
            subtitle={
              api
                ? "Your Nexora search for kind=audio returned no files. Add audio to your roots and pull to refresh."
                : "Connect to your Nexora server to stream FLAC, ALAC, WAV, and DSD. On-device tracks appear automatically."
            }
            action={api ? { label: "Refresh", onPress: () => void refresh() } : { label: "Connect to Nexora", onPress: () => router.push("/login") }}
          />
        ) : null}

        {/* Continue Listening Section */}
        {playback.current && playback.currentTime > 0 && playback.currentTime < playback.duration ? (
          <Section title="Continue Listening" count={1}>
            <View style={{ paddingHorizontal: spacing.lg }}>
              <Pressable
                style={{ flexDirection: "row", alignItems: "center", gap: 12, backgroundColor: colors.card, padding: 12, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.hairline }}
                onPress={() => playback.setShowPlayer(true)}
              >
                <View style={{ width: 48, height: 48, borderRadius: radius.md, overflow: "hidden", backgroundColor: colors.raised }}>
                  {playback.current.artwork.url && <Image source={{ uri: playback.current.artwork.url }} style={{ width: "100%", height: "100%" }} />}
                </View>
                <View style={{ flex: 1, gap: 4 }}>
                  <Text style={{ color: colors.text, fontSize: 14, fontFamily: font.sansBold }} numberOfLines={1}>{playback.current.title}</Text>
                  <Text style={{ color: colors.textMuted, fontSize: 12, fontFamily: font.sansMedium }} numberOfLines={1}>{playback.current.artist || "Unknown"}</Text>
                  <View style={{ height: 4, backgroundColor: "rgba(255,255,255,0.1)", borderRadius: 2, overflow: "hidden", marginTop: 4 }}>
                    <View style={{ height: "100%", width: `${(playback.currentTime / playback.duration) * 100}%`, backgroundColor: accent.primary }} />
                  </View>
                </View>
                <Ionicons name={playback.playing ? "pause" : "play"} size={20} color={colors.text} />
              </Pressable>
            </View>
          </Section>
        ) : null}

        {/* Recently Added Section */}
        {recents.length ? (
          <Section
            title="Recently Added"
            count={recents.length}
            action={{ label: "See all", onPress: () => router.push("/(tabs)/library") }}
          >
            <View style={{ paddingHorizontal: spacing.sm }}>
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

        {/* Albums Carousels */}
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

        {/* Artists Section */}
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
                  size={i === 0 ? 156 : 132}
                />
              ))}
            </ScrollView>
          </Section>
        ) : null}

        {/* Folders Section */}
        {folders.length ? (
          <Section title="Directory Folders" count={folders.length} subtitle="Browse by server & local directory">
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
                return (
                  <FolderCard
                    key={key}
                    name={name}
                    path={rawPath}
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

        {/* Quick Navigation Hub */}
        <View style={{ paddingHorizontal: spacing.lg }}>
          <View style={styles.card}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
              <View style={styles.cardIcon}>
                <Ionicons name="compass-outline" size={20} color={accent.primary} />
              </View>
              <View style={{ flex: 1, gap: 2 }}>
                <Text style={styles.cardTitle}>Audio Hub</Text>
                <Text style={styles.cardBody}>Fast access to your library collections and playlists</Text>
              </View>
            </View>
            <View style={styles.cardRow}>
              <Tile onPress={() => router.push("/(tabs)/library")} icon="library" label="Library" />
              <Tile onPress={() => router.push("/(tabs)/playlists")} icon="musical-notes" label="Playlists" />
              <Tile onPress={() => router.push("/(tabs)/search")} icon="search" label="Search" />
              <Tile onPress={() => router.push("/dsp" as any)} icon="options" label="DSP Studio" />
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
      onPress={() => {
        Haptics.tapLight();
        onPress();
      }}
      style={({ pressed }) => [styles.tile, pressed && styles.tilePressed]}
      accessibilityRole="button"
      accessibilityLabel={label}
    >
      <Ionicons name={icon} size={18} color={accent.primary} />
      <Text style={styles.tileLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: radius.pill,
    backgroundColor: "rgba(251,191,36,0.12)",
    borderWidth: 1,
    borderColor: "rgba(251,191,36,0.35)",
  },
  headerDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: tierColor.hires.accent,
    ...shadow.glow(tierColor.hires.accent, 0.8),
  },
  headerBadgeText: {
    color: tierColor.hires.accent,
    fontSize: 10,
    fontWeight: "900",
    fontFamily: font.monoBold,
    letterSpacing: 0.6,
  },
  heroBanner: {
    borderRadius: radius.xl,
    padding: 18,
    borderWidth: 1,
    borderColor: "rgba(139,92,246,0.35)",
    gap: 14,
    ...shadow.glow(accent.primary, 0.2),
  },
  heroContent: {
    gap: 4,
  },
  heroTag: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  heroTagText: {
    color: "#FBBF24",
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 1.2,
    fontFamily: font.sansBold,
  },
  heroTitle: {
    color: "#fff",
    fontSize: 20,
    fontWeight: "900",
    fontFamily: font.sansBold,
    letterSpacing: -0.3,
  },
  heroSub: {
    color: "rgba(255,255,255,0.75)",
    fontSize: 12,
    lineHeight: 16,
    fontFamily: font.sansRegular,
  },
  heroActions: {
    flexDirection: "row",
    gap: 10,
  },
  heroBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    backgroundColor: accent.primary,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: radius.md,
    ...shadow.glow(accent.primary, 0.4),
  },
  heroBtnText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "800",
    fontFamily: font.sansBold,
  },
  heroBtnGhost: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.08)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: radius.md,
  },
  heroBtnGhostText: {
    color: "#E2E8F0",
    fontSize: 12,
    fontWeight: "700",
    fontFamily: font.sansBold,
  },
  card: {
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    borderRadius: radius.xl,
    padding: 16,
    gap: 14,
    ...shadow.sm,
  },
  cardIcon: {
    width: 42,
    height: 42,
    borderRadius: radius.md,
    backgroundColor: "rgba(139,92,246,0.16)",
    alignItems: "center",
    justifyContent: "center",
  },
  cardTitle: {
    color: colors.text,
    fontWeight: "800",
    fontSize: 15,
    fontFamily: font.sansBold,
  },
  cardBody: {
    color: colors.textMuted,
    fontSize: 12,
    lineHeight: 16,
    fontFamily: font.sansRegular,
  },
  cardRow: {
    flexDirection: "row",
    gap: 8,
  },
  tile: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 12,
    borderRadius: radius.md,
    backgroundColor: "rgba(255,255,255,0.04)",
    borderWidth: 1,
    borderColor: colors.hairline,
    gap: 6,
  },
  tilePressed: {
    backgroundColor: "rgba(139,92,246,0.15)",
    borderColor: accent.primary,
  },
  tileLabel: {
    color: colors.text,
    fontSize: 11,
    fontFamily: font.sansBold,
    fontWeight: "700",
  },
});