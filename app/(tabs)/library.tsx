import React, { useCallback, useMemo, useState } from "react";
import { Alert, Linking, Pressable, RefreshControl, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { requestDevicePermission } from "@/library/device";
import { SegmentedControl } from "@/ui/SegmentedControl";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import { ConnectBanner } from "@/ui/ConnectBanner";
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

export default function LibraryScreen() {
  const lib = useLibrary();
  const playback = usePlayback();
  const [tab, setTab] = useState<Tab>("all");

  const list = useMemo(() => {
    let base = lib.tracks;
    // When the user filters by source, prefer the raw bySource lists so the
    // counts match the tab label and dedupe doesn't hide device-only tracks.
    if (tab === "nexora") base = lib.bySource.nexora;
    if (tab === "device") base = lib.bySource.device;
    if (tab === "offline") base = lib.bySource.offline;
    return filterForTab(base, tab);
  }, [lib.tracks, lib.bySource, tab]);

  const onPlay = useCallback((t: MusicTrack) => { void playback.play(t, list); }, [playback, list]);

  const onRequestDevice = async () => {
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

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <View style={styles.header}>
        <Text style={styles.title}>Library</Text>
        <Pressable onPress={() => void lib.refresh()} style={styles.iconBtn}>
          <Ionicons name="refresh" size={18} color={colors.textMuted} />
        </Pressable>
      </View>

      <View style={{ paddingHorizontal: 16, paddingBottom: 10 }}>
        <SegmentedControl
          value={tab}
          onChange={(v) => setTab(v as Tab)}
          options={[
            { value: "all", label: `All · ${lib.counts.unified}` },
            { value: "nexora", label: `Nexora · ${lib.counts.nexora}` },
            { value: "device", label: `On Device · ${lib.counts.device}` },
          ]}
        />
        <View style={{ height: 8 }} />
        <SegmentedControl
          value={tab}
          onChange={(v) => setTab(v as Tab)}
          options={[
            { value: "offline", label: `Downloads · ${lib.counts.offline}` },
            { value: "favorites", label: "Favorites" },
            { value: "recent", label: "Recent" },
          ]}
        />
      </View>

      {tab === "device" && (lib.devicePermission === "denied" || lib.devicePermission === "undetermined" || lib.devicePermission === "blocked") ? (
        <View style={styles.permBox}>
          <Ionicons name="phone-portrait-outline" size={22} color={colors.text} />
          <Text style={styles.permTitle}>On Device is empty</Text>
          <Text style={styles.permBody}>Allow access to your audio library to see songs stored on this phone. Nexora only reads audio files.</Text>
          <Pressable onPress={onRequestDevice} style={styles.permBtn}>
            <Text style={styles.permBtnLabel}>{lib.devicePermission === "blocked" ? "Open Settings" : "Allow access"}</Text>
          </Pressable>
          <Text style={styles.permHint}>You can change this anytime in system Settings → Nexora → Media.</Text>
        </View>
      ) : null}

      {tab === "nexora" && !lib.bySource.nexora.length && !lib.loading ? (
        <ConnectBanner compact />
      ) : null}

      {tab === "offline" ? (
        <View style={{ padding: 16 }}>
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Offline playback</Text>
            <Text style={styles.cardBody}>Download Nexora tracks for airplane mode. Available in M4 — downloads are queued and `NEXORA_OFFLINE` tracks appear here.</Text>
          </View>
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        <FlashList
          data={list}
          keyExtractor={(item) => item.id}
          
          refreshControl={<RefreshControl refreshing={lib.loading} onRefresh={() => void lib.refresh()} tintColor={colors.text} />}
          renderItem={({ item }) => (
            <TrackRow
              track={item}
              active={playback.current?.id === item.id}
              onPress={() => onPlay(item)}
              onMore={() => router.push({ pathname: "/info/[id]", params: { id: encodeURIComponent(item.id) } })}
            />
          )}
          ListEmptyComponent={
            lib.loading ? (
              <View style={styles.loading}>
                <Text style={styles.loadingText}>Loading…</Text>
              </View>
            ) : tab === "device" && (lib.devicePermission === "denied" || lib.devicePermission === "undetermined" || lib.devicePermission === "blocked") ? null : (
              <EmptyState
                title={tab === "nexora" ? "No Nexora tracks" : tab === "device" ? "No on-device audio" : tab === "offline" ? "No downloads yet" : "No tracks"}
                subtitle={
                  tab === "nexora"
                    ? "Connect to Nexora and add audio to your roots."
                    : tab === "device"
                      ? "Add MP3/FLAC/M4A files to your phone and allow access."
                      : "Nothing here yet."
                }
              />
            )
          }
          contentContainerStyle={{ paddingBottom: 24 }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 16, paddingTop: 12, paddingBottom: 8 },
  title: { color: colors.text, fontSize: 20, fontWeight: "800" },
  iconBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  permBox: { margin: 16, backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 14, padding: 16, alignItems: "center", gap: 8 },
  permTitle: { color: colors.text, fontWeight: "800", fontSize: 14 },
  permBody: { color: colors.textMuted, fontSize: 12, textAlign: "center", lineHeight: 16 },
  permBtn: { backgroundColor: colors.accent, paddingHorizontal: 16, paddingVertical: 10, borderRadius: 10, marginTop: 4 },
  permBtnLabel: { color: "#fff", fontWeight: "800", fontSize: 13 },
  permHint: { color: colors.textMuted, fontSize: 11, textAlign: "center" },
  card: { backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 14, padding: 16, gap: 8 },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 14 },
  cardBody: { color: colors.textMuted, fontSize: 12, lineHeight: 16 },
  loading: { padding: 24, alignItems: "center" },
  loadingText: { color: colors.textMuted, fontSize: 13 },
});