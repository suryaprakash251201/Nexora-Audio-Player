import React, { useMemo, useState } from "react";
import { Alert, Modal, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { useLocalSearchParams, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { colors, font, radius, spacing, accent, shadow } from "@/ui/theme";
import { usePlaylists } from "@/store/PlaylistContext";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { useDownloads } from "@/store/DownloadsContext";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import { SearchBar } from "@/ui/SearchBar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Haptics } from "@/lib/haptics";
import { Toast } from "@/ui/Toast";
import type { MusicTrack } from "@/library/types";
import { mapServerItemToTrack } from "@/library/mapper";
import { isTrashOrHiddenPath } from "@/library/nexora";

export default function PlaylistDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const pl = usePlaylists();
  const lib = useLibrary();
  const playback = usePlayback();
  const downloads = useDownloads();
  const insets = useSafeAreaInsets();
  const [q, setQ] = useState("");
  const [pickMode, setPickMode] = useState(false);
  const [showRename, setShowRename] = useState(false);
  const [renameName, setRenameName] = useState("");

  const playlist = useMemo(() => pl.playlists.find((p) => p.id === id) || null, [pl.playlists, id]);

  const playlistTracks: MusicTrack[] = useMemo(() => {
    if (!playlist) return [];
    const out: MusicTrack[] = [];
    const seen = new Set<string>();
    for (const it of playlist.items) {
      if (isTrashOrHiddenPath(it.path, it.name)) continue;
      const uid = `srv:${it.root_id}:${it.path}`;
      if (seen.has(uid)) continue;
      seen.add(uid);
      out.push(
        mapServerItemToTrack({
          name: it.name,
          path: it.path,
          root_id: it.root_id,
          extension: it.extension,
          mime: it.mime,
          size: it.size,
          modified: it.modified,
          is_dir: false,
        } as any),
      );
    }
    return out;
  }, [playlist]);

  if (!playlist) {
    return (
      <View style={styles.center}>
        <EmptyState
          title="Playlist not found"
          subtitle="It may have been deleted or not yet synced."
          action={{ label: "Back", onPress: () => router.back() }}
        />
      </View>
    );
  }

  const onPlay = (t: MusicTrack) => void playback.play(t, playlistTracks);

  const onPlayAll = () => {
    if (!playlistTracks.length) return;
    Haptics.tapLight();
    playback.setShuffle(false);
    void playback.play(playlistTracks[0], playlistTracks);
  };

  const onShuffleAll = () => {
    if (!playlistTracks.length) return;
    Haptics.tapLight();
    const shuffled = [...playlistTracks].sort(() => Math.random() - 0.5);
    playback.setShuffle(true);
    void playback.play(shuffled[0], shuffled);
  };

  const candidates = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return lib.tracks.slice(0, 50);
    return lib.tracks.filter((t) => `${t.title} ${t.artist ?? ""}`.toLowerCase().includes(needle));
  }, [lib.tracks, q]);

  const onRenameSubmit = async () => {
    const trimmed = renameName.trim();
    if (!trimmed) return;
    try {
      await pl.rename(playlist.id, trimmed);
      Toast.success(`Renamed to “${trimmed}”`);
      setShowRename(false);
    } catch (e: any) {
      Toast.error(e?.message || "Failed to rename");
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      {/* Header Banner */}
      <View style={[styles.headerBanner, { paddingTop: insets.top + 8 }]}>
        <View style={styles.topRow}>
          <Pressable
            onPress={() => {
              Haptics.tapLight();
              router.back();
            }}
            style={styles.iconBtn}
          >
            <Ionicons name="arrow-back" size={18} color={colors.text} />
          </Pressable>
          <View style={{ flex: 1 }}>
            <Text numberOfLines={1} style={styles.title}>{playlist.name}</Text>
            <Text style={styles.meta}>
              {playlist.items.length} tracks {playlist.is_public ? "· Public" : ""} {playlist.description ? `· ${playlist.description}` : ""}
            </Text>
          </View>
        </View>

        {/* Action Controls */}
        <View style={styles.actionRow}>
          <Pressable
            onPress={onPlayAll}
            disabled={!playlistTracks.length}
            style={({ pressed }) => [styles.playAllBtn, !playlistTracks.length && { opacity: 0.5 }, pressed && { opacity: 0.85 }]}
          >
            <Ionicons name="play" size={16} color="#fff" />
            <Text style={styles.playAllText}>Play All</Text>
          </Pressable>
          <Pressable
            onPress={onShuffleAll}
            disabled={!playlistTracks.length}
            style={({ pressed }) => [styles.shuffleBtn, !playlistTracks.length && { opacity: 0.5 }, pressed && { opacity: 0.75 }]}
          >
            <Ionicons name="shuffle" size={16} color="#fff" />
            <Text style={styles.shuffleText}>Shuffle</Text>
          </Pressable>
        </View>

        {/* Toolbar */}
        <View style={styles.toolRow}>
          <Pressable
            onPress={() => {
              Haptics.tapLight();
              setPickMode((v) => !v);
            }}
            style={[styles.smallBtn, pickMode && styles.smallBtnActive]}
          >
            <Ionicons name={pickMode ? "checkmark" : "add"} size={14} color={pickMode ? "#fff" : colors.text} />
            <Text style={[styles.smallBtnLabel, pickMode && { color: "#fff" }]}>{pickMode ? "Done" : "Add tracks"}</Text>
          </Pressable>
          <Pressable
            onPress={() => {
              Haptics.tapLight();
              void downloads.downloadMany(playlistTracks).then(() => Toast.success("Downloading playlist")).catch((e) => Toast.error(String(e?.message || e)));
            }}
            style={[styles.smallBtn, { backgroundColor: "rgba(16,185,129,0.12)", borderColor: "rgba(16,185,129,0.3)" }]}
          >
            <Ionicons name="download-outline" size={14} color="#10B981" />
            <Text style={[styles.smallBtnLabel, { color: "#10B981" }]}>Download</Text>
          </Pressable>
          <Pressable
            onPress={() => {
              Haptics.tapLight();
              setRenameName(playlist.name);
              setShowRename(true);
            }}
            style={styles.smallBtn}
          >
            <Text style={styles.smallBtnLabel}>Rename</Text>
          </Pressable>
          <Pressable
            onPress={() => {
              Haptics.tapMedium();
              Alert.alert("Delete playlist?", `Delete “${playlist.name}”?`, [
                { text: "Cancel", style: "cancel" },
                {
                  text: "Delete",
                  style: "destructive",
                  onPress: () => {
                    void pl.deletePlaylist(playlist.id).then(() => router.back());
                  },
                },
              ]);
            }}
            style={[styles.smallBtn, { borderColor: "rgba(239,68,68,0.3)" }]}
          >
            <Text style={[styles.smallBtnLabel, { color: "#F87171" }]}>Delete</Text>
          </Pressable>
        </View>
      </View>

      {pickMode ? (
        <View style={{ flex: 1 }}>
          <View style={{ paddingHorizontal: spacing.lg, paddingVertical: spacing.sm }}>
            <SearchBar value={q} onChange={setQ} placeholder="Search library to add tracks…" />
            <Text style={styles.hint}>Tap any Nexora track to add it to this playlist.</Text>
          </View>
          <FlashList
            data={candidates}
            keyExtractor={(t) => t.id}
            renderItem={({ item }) => (
              <TrackRow
                track={item}
                onPress={() => {
                  if (!item.serverId) {
                    Alert.alert("Only Nexora server tracks can be added to synced playlists.");
                    return;
                  }
                  Haptics.tapLight();
                  void pl.addItems(playlist.id, [{ root_id: item.serverId.rootId, path: item.serverId.path }]);
                  Toast.success(`Added “${item.title}”`);
                }}
              />
            )}
            ListEmptyComponent={<EmptyState title="No matches" subtitle="Try a different search query." />}
          />
        </View>
      ) : (
        <FlashList
          data={playlistTracks}
          keyExtractor={(t) => t.id}
          contentContainerStyle={{ paddingBottom: 130 }}
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
                  Alert.alert(item.title, isDownloading ? `Downloading ${Math.round((dlProg ?? 0) * 100)}%` : isDL ? "Available offline" : undefined, [
                    { text: "Cancel", style: "cancel" },
                    { text: "Play", onPress: () => onPlay(item) },
                    { text: "Play next", onPress: () => { const mt = lib.tracks.find((x) => x.id === item.id) ?? item; void playback.playNext(mt as any); } },
                    ...(!isDL && !isDownloading && item.serverId ? [{ text: "Download", onPress: () => void downloads.download(item).catch((e) => Toast.error(String(e?.message || e))) } as const] : []),
                    ...(isDL ? [{ text: "Remove download", style: "destructive" as const, onPress: () => void downloads.remove(item.id) } as const] : []),
                    {
                      text: "Remove from playlist",
                      style: "destructive",
                      onPress: () => {
                        const pidItem = playlist.items[index];
                        if (pidItem) void pl.removeItem(playlist.id, pidItem.id);
                      },
                    },
                    {
                      text: "Move to top",
                      onPress: () => {
                        const ids = playlist.items.map((it) => it.id);
                        const cur = ids[index];
                        if (cur != null) {
                          ids.splice(index, 1);
                          ids.unshift(cur);
                          void pl.reorder(playlist.id, ids);
                        }
                      },
                    },
                  ]);
                }}
              />
            );
          }}
          ListEmptyComponent={
            <EmptyState
              title="Empty playlist"
              subtitle="Tap “Add tracks” to add songs from your library. All changes sync seamlessly."
              action={{ label: "Add tracks", onPress: () => setPickMode(true) }}
            />
          }
        />
      )}

      {/* Rename Modal */}
      <Modal visible={showRename} transparent animationType="fade" onRequestClose={() => setShowRename(false)}>
        <Pressable style={styles.modalOverlay} onPress={() => setShowRename(false)}>
          <Pressable style={[styles.modalCard, { paddingBottom: insets.bottom + 16 }]} onPress={(e) => e.stopPropagation()}>
            <Text style={styles.modalTitle}>Rename Playlist</Text>
            <Text style={styles.modalLabel}>Name</Text>
            <TextInput
              value={renameName}
              onChangeText={setRenameName}
              placeholder="Playlist name"
              placeholderTextColor={colors.textMuted}
              style={styles.modalInput}
              autoFocus
            />
            <View style={{ flexDirection: "row", gap: 10, marginTop: 12 }}>
              <Pressable onPress={() => setShowRename(false)} style={[styles.modalBtn, styles.modalGhost]}>
                <Text style={[styles.modalBtnLabel, { color: colors.text }]}>Cancel</Text>
              </Pressable>
              <Pressable onPress={onRenameSubmit} style={[styles.modalBtn, { backgroundColor: accent.primary }]}>
                <Text style={[styles.modalBtnLabel, { color: "#fff" }]}>Save</Text>
              </Pressable>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    backgroundColor: colors.bg,
    alignItems: "center",
    justifyContent: "center",
    padding: 16,
  },
  headerBanner: {
    backgroundColor: colors.card,
    borderBottomWidth: 1,
    borderBottomColor: colors.hairlineStrong,
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.md,
    gap: 12,
  },
  topRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  iconBtn: {
    width: 38,
    height: 38,
    borderRadius: radius.md,
    backgroundColor: "rgba(255,255,255,0.06)",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  title: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "900",
    fontFamily: font.sansBold,
    letterSpacing: -0.3,
  },
  meta: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansMedium,
    marginTop: 2,
  },
  actionRow: {
    flexDirection: "row",
    gap: 10,
  },
  playAllBtn: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    backgroundColor: accent.primary,
    height: 42,
    borderRadius: radius.md,
    ...shadow.glow(accent.primary, 0.4),
  },
  playAllText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "800",
    fontFamily: font.sansBold,
  },
  shuffleBtn: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.08)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.14)",
    height: 42,
    borderRadius: radius.md,
  },
  shuffleText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "800",
    fontFamily: font.sansBold,
  },
  toolRow: {
    flexDirection: "row",
    gap: 8,
    flexWrap: "wrap",
  },
  smallBtn: {
    flexDirection: "row",
    gap: 6,
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    paddingHorizontal: 12,
    height: 32,
    borderRadius: radius.xs,
  },
  smallBtnActive: {
    backgroundColor: accent.primary,
    borderColor: accent.primary,
  },
  smallBtnLabel: {
    color: colors.text,
    fontWeight: "700",
    fontSize: 11,
    fontFamily: font.sansBold,
  },
  hint: {
    color: colors.textMuted,
    fontSize: 11,
    marginTop: 6,
    textAlign: "center",
    fontFamily: font.sansRegular,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.65)",
    justifyContent: "flex-end",
  },
  modalCard: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    padding: 20,
    gap: 10,
    borderTopWidth: 1,
    borderTopColor: colors.hairlineStrong,
  },
  modalTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: "900",
    fontFamily: font.sansBold,
  },
  modalLabel: {
    color: colors.textMuted,
    fontSize: 11,
    fontWeight: "800",
    fontFamily: font.sansBold,
    textTransform: "uppercase",
    letterSpacing: 0.8,
  },
  modalInput: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: radius.md,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: colors.text,
    fontSize: 14,
    fontFamily: font.sansMedium,
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  modalBtn: {
    flex: 1,
    height: 44,
    borderRadius: radius.md,
    alignItems: "center",
    justifyContent: "center",
  },
  modalGhost: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  modalBtnLabel: {
    fontSize: 13,
    fontWeight: "800",
    fontFamily: font.sansBold,
  },
});