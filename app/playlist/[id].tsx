import React, { useMemo, useState } from "react";
import { Alert, Pressable, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { useLocalSearchParams, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { usePlaylists } from "@/store/PlaylistContext";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { useDownloads } from "@/store/DownloadsContext";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import { SearchBar } from "@/ui/SearchBar";
import type { MusicTrack } from "@/library/types";
import { mapServerItemToTrack } from "@/library/mapper";

export default function PlaylistDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const pl = usePlaylists();
  const lib = useLibrary();
  const playback = usePlayback();
  const downloads = useDownloads();
  const [q, setQ] = useState("");
  const [pickMode, setPickMode] = useState(false);

  const playlist = useMemo(() => pl.playlists.find((p) => p.id === id) || null, [pl.playlists, id]);

  if (!playlist) {
    return (
      <View style={s.center}>
        <EmptyState title="Playlist not found" subtitle="It may have been deleted or not yet synced." action={{ label: "Back", onPress: () => router.back() }} />
      </View>
    );
  }

  const playlistTracks: MusicTrack[] = playlist.items.map((it) =>
    mapServerItemToTrack({ name: it.name, path: it.path, root_id: it.root_id, extension: it.extension, mime: it.mime, size: it.size, modified: it.modified, is_dir: false } as any),
  );

  const onPlay = (t: MusicTrack) => void playback.play(t, playlistTracks);

  const candidates = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return lib.tracks.slice(0, 50);
    return lib.tracks.filter((t) => `${t.title} ${t.artist ?? ""}`.toLowerCase().includes(needle));
  }, [lib.tracks, q]);

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <View style={s.header}>
        <Pressable onPress={() => router.back()} style={s.iconBtn}>
          <Ionicons name="arrow-back" size={18} color={colors.text} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text numberOfLines={1} style={s.title}>{playlist.name}</Text>
          <Text style={s.meta}>{playlist.items.length} tracks {playlist.is_public ? "· Public" : ""} {playlist.description ? `· ${playlist.description}` : ""}</Text>
        </View>
        <Pressable onPress={() => { if (playlistTracks.length) void playback.play(playlistTracks[0], playlistTracks); }} style={s.playBtn}>
          <Ionicons name="play" size={18} color="#fff" />
        </Pressable>
      </View>

      <View style={{ flexDirection: "row", gap: 8, paddingHorizontal: 16, paddingBottom: 10 }}>
        <Pressable onPress={() => setPickMode((v) => !v)} style={[s.smallBtn, pickMode && { backgroundColor: colors.accent }]}>
          <Ionicons name="add" size={14} color={pickMode ? "#fff" : colors.text} />
          <Text style={[s.smallBtnLabel, pickMode && { color: "#fff" }]}>{pickMode ? "Done" : "Add tracks"}</Text>
        </Pressable>
        <Pressable
          onPress={() => void downloads.downloadMany(playlistTracks).catch((e) => Alert.alert("Download failed", String(e?.message || e)))}
          style={[s.smallBtn, { backgroundColor: "rgba(34,197,94,0.12)", borderColor: "rgba(34,197,94,0.22)" }]}
        >
          <Ionicons name="download-outline" size={14} color="#22C55E" />
          <Text style={[s.smallBtnLabel, { color: "#22C55E" }]}>Download</Text>
        </Pressable>
        <Pressable
          onPress={() => {
            Alert.alert("Rename playlist", undefined, [
              { text: "Cancel", style: "cancel" },
              { text: "Rename", onPress: () => {
                // use prompt shim: Alert.prompt not on Android — fall back to simple
                // For M3 we keep it minimal: use a hard-coded suffix to prove the flow.
                const newName = `${playlist.name} (renamed)`;
                void pl.rename(playlist.id, newName);
              }},
            ]);
          }}
          style={s.smallBtn}
        >
          <Text style={s.smallBtnLabel}>Rename</Text>
        </Pressable>
        <Pressable
          onPress={() => {
            Alert.alert("Delete playlist?", `Delete “${playlist.name}”?`, [
              { text: "Cancel", style: "cancel" },
              { text: "Delete", style: "destructive", onPress: () => { void pl.deletePlaylist(playlist.id).then(() => router.back()); } },
            ]);
          }}
          style={[s.smallBtn, { borderColor: "rgba(248,113,113,0.22)" }]}
        >
          <Text style={[s.smallBtnLabel, { color: "#FCA5A5" }]}>Delete</Text>
        </Pressable>
      </View>

      {pickMode ? (
        <View style={{ flex: 1 }}>
          <View style={{ paddingHorizontal: 16, paddingBottom: 10 }}>
            <SearchBar value={q} onChange={setQ} placeholder="Search your library to add…" />
            <Text style={s.hint}>Tap a track to add it to this playlist (queues and syncs).</Text>
          </View>
          <FlashList
            data={candidates}
            keyExtractor={(t) => t.id}
            renderItem={({ item }) => (
              <TrackRow
                track={item}
                onPress={() => {
                  if (!item.serverId) { Alert.alert("Only Nexora tracks can be added (server needs root+path)."); return; }
                  void pl.addItems(playlist.id, [{ root_id: item.serverId.rootId, path: item.serverId.path }]);
                }}
              />
            )}
            ListEmptyComponent={<EmptyState title="No matches" subtitle="Try a different search." />}
          />
        </View>
      ) : (
        <FlashList
          data={playlistTracks}
          keyExtractor={(t) => t.id}
          renderItem={({ item, index }) => {
            const dlState = downloads.stateByTrackId[item.id] as any;
            const dlProg = downloads.progressByTrackId[item.id];
            return (
              <TrackRow
                track={item}
                active={playback.current?.id === item.id}
                downloadState={dlState}
                downloadProgress={dlProg}
                onPress={() => onPlay(item)}
                onMore={() => {
                  const isDL = dlState === "AVAILABLE_OFFLINE";
                  const isDownloading = dlState === "DOWNLOADING";
                  Alert.alert(item.title, isDownloading ? `Downloading ${Math.round((dlProg ?? 0)*100)}%` : isDL ? "Available offline" : undefined, [
                    { text: "Cancel", style: "cancel" },
                    { text: "Play", onPress: () => onPlay(item) },
                    { text: "Play next", onPress: () => { const mt = lib.tracks.find((x) => x.id === item.id) ?? item; void playback.playNext(mt as any); } },
                    ...(!isDL && !isDownloading && item.serverId ? [{ text: "Download", onPress: () => void downloads.download(item).catch((e)=>Alert.alert("Download failed", String(e?.message||e))) } as const] : []),
                    ...(isDL ? [{ text: "Remove download", style: "destructive" as const, onPress: () => void downloads.remove(item.id) } as const] : []),
                    { text: "Remove from playlist", style: "destructive", onPress: () => {
                      const pidItem = playlist.items[index];
                      if (pidItem) void pl.removeItem(playlist.id, pidItem.id);
                    }},
                    { text: "Move to top", onPress: () => {
                      const ids = playlist.items.map((it) => it.id);
                      const cur = ids[index];
                      if (cur != null) { ids.splice(index, 1); ids.unshift(cur); void pl.reorder(playlist.id, ids); }
                    }},
                  ]);
                }}
              />
            );
          }}
          ListEmptyComponent={<EmptyState title="Empty playlist" subtitle="Add tracks with “Add tracks” above. Changes are queued and sync when online." />}
        />
      )}
    </View>
  );
}

const s = StyleSheet.create({
  center: { flex: 1, backgroundColor: colors.bg, alignItems: "center", justifyContent: "center", padding: 16 },
  header: { flexDirection: "row", alignItems: "center", gap: 12, paddingHorizontal: 12, paddingTop: 10, paddingBottom: 8 },
  iconBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  title: { color: colors.text, fontSize: 16, fontWeight: "800" },
  meta: { color: colors.textMuted, fontSize: 11, marginTop: 2 },
  playBtn: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center" },
  smallBtn: { flexDirection: "row", gap: 6, alignItems: "center", backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, paddingHorizontal: 12, height: 34, borderRadius: 10 },
  smallBtnLabel: { color: colors.text, fontWeight: "700", fontSize: 12 },
  hint: { color: colors.textMuted, fontSize: 11, marginTop: 6, textAlign: "center" },
});