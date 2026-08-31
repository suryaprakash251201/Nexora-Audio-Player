import React, { useCallback, useMemo, useState } from "react";
import { Alert, Linking, Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, spacing, accent, shadow, tierColor } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { useDownloads } from "@/store/DownloadsContext";
import { requestDevicePermission } from "@/library/device";
import { TrackRow } from "@/ui/TrackRow";
import { AlbumCard } from "@/ui/AlbumCard";
import { EmptyState } from "@/ui/EmptyState";
import { ConnectBanner } from "@/ui/ConnectBanner";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { useLayout } from "@/ui/layout";
import { Toast } from "@/ui/Toast";
import { Haptics } from "@/lib/haptics";
import { router } from "expo-router";
import { SkeletonList } from "@/ui/Skeleton";
import type { MusicTrack } from "@/library/types";

type Tab = "all" | "nexora" | "device" | "offline" | "favorites" | "recent";
type SortBy = "default" | "az" | "za" | "duration" | "newest";

function filterForTab(tracks: MusicTrack[], tab: Tab): MusicTrack[] {
  switch (tab) {
    case "all": return tracks;
    case "nexora": return tracks.filter((t) => t.source === "NEXORA_REMOTE");
    case "device": return tracks.filter((t) => t.source === "DEVICE_LOCAL");
    case "offline": return tracks.filter((t) => t.source === "NEXORA_OFFLINE" || t.download.state === "AVAILABLE_OFFLINE");
    case "favorites": return tracks.filter((t) => t.favorite);
    case "recent": return [...tracks].sort((a, b) => Date.parse(b.modifiedAt || "0") - Date.parse(a.modifiedAt || "0")).slice(0, 100);
  }
}

const TABS: { value: Tab; label: string; icon: keyof typeof Ionicons.glyphMap; accent: string }[] = [
  { value: "all", label: "All", icon: "infinite", accent: colors.text },
  { value: "nexora", label: "Nexora", icon: "cloud", accent: "#38BDF8" },
  { value: "device", label: "On Device", icon: "phone-portrait", accent: "#10B981" },
  { value: "offline", label: "Downloads", icon: "cloud-download", accent: "#FBBF24" },
  { value: "favorites", label: "Favorites", icon: "heart", accent: "#F87171" },
  { value: "recent", label: "Recent", icon: "time", accent: "#06B6D4" },
];

export default function LibraryScreen() {
  const lib = useLibrary();
  const playback = usePlayback();
  const downloads = useDownloads();
  const { isLandscape } = useLayout();
  const [tab, setTab] = useState<Tab>("all");
  const [sortBy, setSortBy] = useState<SortBy>("default");
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");

  const list = useMemo(() => {
    let base = lib.tracks;
    if (tab === "nexora") base = lib.bySource.nexora;
    if (tab === "device") base = lib.bySource.device;
    if (tab === "offline") base = lib.bySource.offline;
    return filterForTab(base, tab);
  }, [lib.tracks, lib.bySource, tab]);

  const sortedList = useMemo(() => {
    if (sortBy === "default") return list;
    const copy = [...list];
    switch (sortBy) {
      case "az": return copy.sort((a, b) => a.title.localeCompare(b.title));
      case "za": return copy.sort((a, b) => b.title.localeCompare(a.title));
      case "duration": return copy.sort((a, b) => (b.metadata.durationSec ?? 0) - (a.metadata.durationSec ?? 0));
      case "newest": return copy.sort((a, b) => Date.parse(b.modifiedAt || "0") - Date.parse(a.modifiedAt || "0"));
    }
  }, [list, sortBy]);

  const onPlay = useCallback((t: MusicTrack) => { void playback.play(t, sortedList); }, [playback, sortedList]);

  const onRequestDevice = async () => {
    Haptics.tapLight();
    const res = await requestDevicePermission();
    if (res === "blocked") {
      Alert.alert("Permission required", "Nexora needs audio library access. Open Settings to allow it.", [
        { text: "Cancel", style: "cancel" },
        { text: "Open Settings", onPress: () => void Linking.openSettings() },
      ]);
    }
    void lib.refresh();
    void lib.refreshDevicePermission();
  };

  const devicePermNeeded = tab === "device" && (lib.devicePermission === "denied" || lib.devicePermission === "undetermined" || lib.devicePermission === "blocked");

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Library Collection"
        title="Your Music"
        subtitle={`${lib.counts.unified.toLocaleString()} tracks · ${(lib.bySource.nexora.length + lib.bySource.device.length + lib.bySource.offline.length).toLocaleString()} indexed`}
        right={
          <View style={{ flexDirection: "row", gap: 8 }}>
            <Pressable
              onPress={() => {
                Haptics.tapLight();
                setViewMode((v) => (v === "list" ? "grid" : "list"));
              }}
              hitSlop={10}
              style={styles.iconBtn}
              accessibilityLabel="Toggle view"
            >
              <Ionicons name={viewMode === "list" ? "grid-outline" : "list-outline"} size={18} color={accent.primary} />
            </Pressable>
            <Pressable
              onPress={() => {
                Haptics.tapLight();
                void lib.refresh();
              }}
              hitSlop={10}
              style={styles.iconBtn}
              accessibilityLabel="Refresh library"
            >
              <Ionicons name="refresh" size={18} color={colors.textDim} />
            </Pressable>
          </View>
        }
      />

      {/* Tabs Filter Bar */}
      <View style={styles.tabScrollerWrap}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.tabScroller}
        >
          {TABS.map((t) => {
            const active = tab === t.value;
            const count =
              t.value === "all" ? lib.counts.unified :
              t.value === "nexora" ? lib.counts.nexora :
              t.value === "device" ? lib.counts.device :
              t.value === "offline" ? lib.counts.offline :
              t.value === "favorites" ? lib.tracks.filter((x) => x.favorite).length :
              Math.min(100, lib.tracks.length);
            return (
              <Pressable
                key={t.value}
                onPress={() => {
                  Haptics.selection();
                  setTab(t.value);
                }}
                style={[styles.chip, active && styles.chipOn]}
              >
                <Ionicons name={t.icon} size={14} color={active ? "#fff" : t.accent} />
                <Text style={[styles.chipLabel, active && styles.chipLabelOn]}>{t.label}</Text>
                <View style={[styles.chipCount, active && styles.chipCountOn]}>
                  <Text style={[styles.chipCountText, active && { color: "#fff" }]}>{count.toLocaleString()}</Text>
                </View>
              </Pressable>
            );
          })}
        </ScrollView>
      </View>

      {/* Sort Options Strip */}
      <View style={styles.sortRow}>
        {(["default", "az", "za", "duration", "newest"] as const).map((s) => {
          const labels: Record<string, string> = { default: "Default", az: "A → Z", za: "Z → A", duration: "Duration", newest: "Newest" };
          const active = sortBy === s;
          return (
            <Pressable
              key={s}
              onPress={() => {
                Haptics.selection();
                setSortBy(s);
              }}
              style={[styles.sortChip, active && styles.sortChipOn]}
            >
              <Text style={[styles.sortChipLabel, active && styles.sortChipLabelOn]}>{labels[s]}</Text>
            </Pressable>
          );
        })}
      </View>

      {devicePermNeeded ? (
        <View style={styles.permBox}>
          <View style={styles.permIcon}>
            <Ionicons name="phone-portrait-outline" size={24} color="#10B981" />
          </View>
          <Text style={styles.permTitle}>Allow access to your music</Text>
          <Text style={styles.permBody}>Nexora reads local audio files (MP3, FLAC, M4A, DSD) to integrate your device library.</Text>
          <Pressable onPress={onRequestDevice} style={styles.permBtn}>
            <Text style={styles.permBtnLabel}>{lib.devicePermission === "blocked" ? "Open Settings" : "Allow access"}</Text>
          </Pressable>
        </View>
      ) : null}

      {tab === "nexora" && !lib.bySource.nexora.length && !lib.loading ? (
        <View style={{ paddingHorizontal: spacing.lg, marginBottom: spacing.md }}>
          <ConnectBanner compact />
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        {lib.loading ? (
          <View style={{ paddingHorizontal: spacing.lg, paddingTop: 10 }}>
            <SkeletonList count={6} />
          </View>
        ) : (
          <FlashList
            data={sortedList}
            keyExtractor={(item) => item.id}
            numColumns={viewMode === "grid" ? 2 : 1}
            key={viewMode}
            refreshControl={<RefreshControl refreshing={lib.loading} onRefresh={() => void lib.refresh()} tintColor={accent.primary} />}
            renderItem={({ item }) => {
              const dlState = downloads.stateByTrackId[item.id] ?? (item.source === "NEXORA_OFFLINE" ? "AVAILABLE_OFFLINE" : undefined);
              const dlProg = downloads.progressByTrackId[item.id] ?? (dlState === "DOWNLOADING" ? 0.5 : undefined);

              if (viewMode === "grid") {
                return (
                  <View style={{ flex: 1, padding: 6 }}>
                    <AlbumCard
                      title={item.title}
                      subtitle={item.artist || item.album || "Unknown"}
                      count={1}
                      cover={item.artwork.url}
                      width={160}
                      onPress={() => onPlay(item)}
                    />
                  </View>
                );
              }

              return (
                <TrackRow
                  track={item}
                  active={playback.current?.id === item.id}
                  downloadState={dlState as any}
                  downloadProgress={dlProg}
                  onPress={() => onPlay(item)}
                  onMore={() => {
                    const isRemote = item.source === "NEXORA_REMOTE" && !!item.serverId;
                    const isOffline = dlState === "AVAILABLE_OFFLINE" || item.source === "NEXORA_OFFLINE";
                    const isDownloading = dlState === "DOWNLOADING";
                    Alert.alert(item.title, isDownloading ? `Downloading… ${Math.round((dlProg ?? 0) * 100)}%` : isOffline ? "Available offline" : "Options", [
                      { text: "Cancel", style: "cancel" },
                      { text: "Play", onPress: () => onPlay(item) },
                      { text: "Play next", onPress: () => { const mt = lib.tracks.find((x) => x.id === item.id) ?? item; void playback.playNext(mt); } },
                      ...(isRemote && !isOffline && !isDownloading ? [{ text: "Download", onPress: () => void downloads.download(item).then(() => Toast.success("Downloaded")).catch((e) => Toast.error(`Download failed: ${e?.message || e}`)) } as const] : []),
                      ...(isOffline ? [{ text: "Remove download", style: "destructive" as const, onPress: () => void downloads.remove(item.id) } as const] : []),
                      ...(isDownloading ? [{ text: "Cancel download", style: "destructive" as const, onPress: () => void downloads.remove(item.id) } as const] : []),
                      { text: "Details", onPress: () => router.push({ pathname: "/info/[id]", params: { id: encodeURIComponent(item.id) } }) },
                    ]);
                  }}
                />
              );
            }}
            ListEmptyComponent={
              devicePermNeeded ? null : (
                <EmptyState
                  title={
                    tab === "nexora" ? "No Nexora tracks yet" :
                    tab === "device" ? "No on-device audio" :
                    tab === "offline" ? "No downloads yet" :
                    tab === "favorites" ? "No favorites yet" :
                    tab === "recent" ? "Nothing recent" :
                    "No tracks"
                  }
                  subtitle={
                    tab === "nexora" ? "Add audio to your roots and pull to refresh." :
                    tab === "device" ? "Add MP3/FLAC/M4A files to your phone and allow access." :
                    tab === "offline" ? "Download any Nexora track to play it without a network." :
                    tab === "favorites" ? "Tap the heart on any track to keep it here." :
                    "Tracks you play will appear here."
                  }
                />
              )
            }
            contentContainerStyle={{ paddingBottom: 130 }}
          />
        )}
      </View>
    </Container>
  );
}

const styles = StyleSheet.create({
  iconBtn: {
    width: 38,
    height: 38,
    borderRadius: radius.md,
    backgroundColor: colors.card,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
  },
  tabScrollerWrap: {
    paddingTop: 4,
    paddingBottom: 8,
  },
  tabScroller: {
    paddingHorizontal: spacing.lg,
    gap: 8,
    alignItems: "center",
  },
  chip: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: radius.pill,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
  },
  chipOn: {
    backgroundColor: accent.primary,
    borderColor: accent.primary,
    ...shadow.glow(accent.primary, 0.35),
  },
  chipLabel: {
    color: colors.textDim,
    fontSize: 12,
    fontFamily: font.sansBold,
    fontWeight: "700",
  },
  chipLabelOn: {
    color: "#fff",
  },
  chipCount: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: radius.pill,
    backgroundColor: "rgba(255,255,255,0.08)",
  },
  chipCountOn: {
    backgroundColor: "rgba(255,255,255,0.22)",
  },
  chipCountText: {
    color: colors.textMuted,
    fontSize: 10,
    fontFamily: font.monoBold,
    fontWeight: "800",
  },
  sortRow: {
    flexDirection: "row",
    paddingHorizontal: spacing.lg,
    gap: 6,
    paddingBottom: 8,
  },
  sortChip: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: radius.xs,
    backgroundColor: "rgba(255,255,255,0.04)",
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  sortChipOn: {
    backgroundColor: "rgba(139,92,246,0.18)",
    borderColor: accent.primary,
  },
  sortChipLabel: {
    color: colors.textMuted,
    fontSize: 10,
    fontFamily: font.monoBold,
    fontWeight: "700",
  },
  sortChipLabelOn: {
    color: accent.primary,
  },
  permBox: {
    marginHorizontal: spacing.lg,
    marginBottom: spacing.md,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    borderRadius: radius.xl,
    padding: 20,
    alignItems: "center",
    gap: 8,
  },
  permIcon: {
    width: 56,
    height: 56,
    borderRadius: radius.lg,
    backgroundColor: "rgba(16,185,129,0.16)",
    alignItems: "center",
    justifyContent: "center",
  },
  permTitle: {
    color: colors.text,
    fontWeight: "800",
    fontSize: 16,
    fontFamily: font.sansBold,
  },
  permBody: {
    color: colors.textMuted,
    fontSize: 12,
    textAlign: "center",
    lineHeight: 18,
    fontFamily: font.sansRegular,
  },
  permBtn: {
    backgroundColor: accent.primary,
    paddingHorizontal: 22,
    paddingVertical: 12,
    borderRadius: radius.md,
    marginTop: 6,
    ...shadow.glow(accent.primary, 0.4),
  },
  permBtnLabel: {
    color: "#fff",
    fontWeight: "800",
    fontSize: 13,
    fontFamily: font.sansBold,
  },
});