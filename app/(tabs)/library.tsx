import React, { useCallback, useMemo, useState } from "react";
import { Alert, Linking, Pressable, RefreshControl, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, spacing } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { useDownloads } from "@/store/DownloadsContext";
import { requestDevicePermission } from "@/library/device";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import { ConnectBanner } from "@/ui/ConnectBanner";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { useLayout } from "@/ui/layout";
import { Toast } from "@/ui/Toast";
import { Haptics } from "@/lib/haptics";
import { router } from "expo-router";
import type { MusicTrack } from "@/library/types";

type Tab = "all" | "nexora" | "device" | "offline" | "favorites" | "recent";

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
  { value: "nexora", label: "Nexora", icon: "cloud", accent: "#60A5FA" },
  { value: "device", label: "On Device", icon: "phone-portrait", accent: "#22C55E" },
  { value: "offline", label: "Downloads", icon: "cloud-download", accent: "#F5C451" },
  { value: "favorites", label: "Favorites", icon: "heart", accent: "#F87171" },
  { value: "recent", label: "Recent", icon: "time", accent: "#22D3EE" },
];

export default function LibraryScreen() {
  const lib = useLibrary();
  const playback = usePlayback();
  const downloads = useDownloads();
  const { isLandscape } = useLayout();
  const [tab, setTab] = useState<Tab>("all");

  const list = useMemo(() => {
    let base = lib.tracks;
    if (tab === "nexora") base = lib.bySource.nexora;
    if (tab === "device") base = lib.bySource.device;
    if (tab === "offline") base = lib.bySource.offline;
    return filterForTab(base, tab);
  }, [lib.tracks, lib.bySource, tab]);

  const onPlay = useCallback((t: MusicTrack) => { void playback.play(t, list); }, [playback, list]);

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
        kicker="Library"
        title="Your music"
        subtitle={`${lib.counts.unified.toLocaleString()} tracks · ${(lib.bySource.nexora.length + lib.bySource.device.length + lib.bySource.offline.length).toLocaleString()} indexed`}
        right={
          <Pressable onPress={() => { Haptics.tapLight(); void lib.refresh(); }} hitSlop={10} style={styles.iconBtn} accessibilityLabel="Refresh library">
            <Ionicons name="refresh" size={18} color={colors.textMuted} />
          </Pressable>
        }
      />

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
              t.value === "favorites" ? 0 :
              Math.min(100, lib.tracks.length);
            return (
              <Pressable
                key={t.value}
                onPress={() => { Haptics.selection(); setTab(t.value); }}
                style={[styles.chip, active && styles.chipOn]}
              >
                <Ionicons name={t.icon} size={14} color={active ? "#fff" : t.accent} />
                <Text style={[styles.chipLabel, active && styles.chipLabelOn]}>{t.label}</Text>
                <View style={[styles.chipCount, active && { backgroundColor: "rgba(255,255,255,0.18)" }]}>
                  <Text style={[styles.chipCountText, active && { color: "#fff" }]}>{count.toLocaleString()}</Text>
                </View>
              </Pressable>
            );
          })}
        </ScrollView>
      </View>

      {devicePermNeeded ? (
        <View style={styles.permBox}>
          <View style={styles.permIcon}>
            <Ionicons name="phone-portrait-outline" size={22} color={colors.text} />
          </View>
          <Text style={styles.permTitle}>Allow access to your music</Text>
          <Text style={styles.permBody}>Nexora only reads audio files (MP3, FLAC, M4A…). You can change this anytime in Settings → Nexora → Media.</Text>
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

      {tab === "offline" && !lib.bySource.offline.length ? (
        <View style={{ paddingHorizontal: spacing.lg, marginBottom: spacing.md }}>
          <View style={styles.card}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
              <View style={styles.cardIcon}><Ionicons name="cloud-download" size={18} color="#F5C451" /></View>
              <View style={{ flex: 1 }}>
                <Text style={styles.cardTitle}>Offline playback</Text>
                <Text style={styles.cardBody}>Download Nexora tracks for airplane mode. Tap Download on any Nexora track, or use “Download playlist” in a playlist.</Text>
              </View>
            </View>
          </View>
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        <FlashList
          data={list}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={lib.loading} onRefresh={() => void lib.refresh()} tintColor={colors.text} />}
          renderItem={({ item }) => {
            const dlState = downloads.stateByTrackId[item.id] ?? (item.source === "NEXORA_OFFLINE" ? "AVAILABLE_OFFLINE" : undefined);
            const dlProg = downloads.progressByTrackId[item.id] ?? (dlState === "DOWNLOADING" ? 0.5 : undefined);
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
            lib.loading ? (
              <View style={styles.loading}><Text style={styles.loadingText}>Loading…</Text></View>
            ) : devicePermNeeded ? null : (
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
          contentContainerStyle={{ paddingBottom: 120 }}
        />
      </View>
    </Container>
  );
}

// ScrollView with horizontal prop without using react-native-scrollview is fine in RN 0.81
import { ScrollView } from "react-native";

const styles = StyleSheet.create({
  iconBtn: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.card, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  tabScrollerWrap: { paddingTop: 4, paddingBottom: 10 },
  tabScroller: { paddingHorizontal: spacing.lg, gap: 8, alignItems: "center" },
  chip: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 999, backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline },
  chipOn: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipLabel: { color: colors.textDim, fontSize: 12, fontFamily: font.sansSemibold, fontWeight: "700" },
  chipLabelOn: { color: "#fff" },
  chipCount: { paddingHorizontal: 6, paddingVertical: 1, borderRadius: 999, backgroundColor: "rgba(255,255,255,0.08)" },
  chipCountText: { color: colors.textMuted, fontSize: 10, fontFamily: font.sansMedium, fontWeight: "800" },
  permBox: { marginHorizontal: spacing.lg, marginBottom: spacing.md, backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, borderRadius: radius.lg, padding: 20, alignItems: "center", gap: 8 },
  permIcon: { width: 56, height: 56, borderRadius: 16, backgroundColor: "rgba(34,197,94,0.16)", alignItems: "center", justifyContent: "center" },
  permTitle: { color: colors.text, fontWeight: "800", fontSize: 16, fontFamily: font.sansBold },
  permBody: { color: colors.textMuted, fontSize: 12, textAlign: "center", lineHeight: 18, fontFamily: font.sansRegular },
  permBtn: { backgroundColor: colors.accent, paddingHorizontal: 22, paddingVertical: 12, borderRadius: 12, marginTop: 6, shadowColor: colors.accent, shadowOpacity: 0.3, shadowRadius: 10, shadowOffset: { width: 0, height: 4 }, elevation: 6 },
  permBtnLabel: { color: "#fff", fontWeight: "800", fontSize: 13, fontFamily: font.sansBold },
  card: { backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, borderRadius: radius.lg, padding: 16, gap: 8 },
  cardIcon: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(245,196,81,0.16)", alignItems: "center", justifyContent: "center" },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 14, fontFamily: font.sansBold },
  cardBody: { color: colors.textMuted, fontSize: 12, lineHeight: 16, fontFamily: font.sansRegular },
  loading: { padding: 24, alignItems: "center" },
  loadingText: { color: colors.textMuted, fontSize: 13, fontFamily: font.sansMedium },
});