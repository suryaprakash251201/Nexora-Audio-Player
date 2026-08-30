import React, { useEffect, useState } from "react";
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { useLocalSearchParams, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { usePlayback } from "@/store/PlaybackContext";
import { mapServerItemToTrack } from "@/library/mapper";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import type { Playlist } from "@/api/types";
import type { MusicTrack } from "@/library/types";

export default function PlaylistDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { api } = useSession();
  const playback = usePlayback();
  const [pl, setPl] = useState<Playlist | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!api || !id) { setLoading(false); return; }
    (async () => {
      try {
        const res = await api.listPlaylists();
        const found = (res.items || []).find((p) => p.id === id) ?? null;
        setPl(found);
      } catch {
        setPl(null);
      } finally {
        setLoading(false);
      }
    })();
  }, [api, id]);

  if (loading) {
    return <View style={s.center}><ActivityIndicator color={colors.text} /></View>;
  }
  if (!pl) {
    return (
      <View style={s.center}>
        <EmptyState title="Playlist not found" subtitle="It may have been deleted." action={{ label: "Back", onPress: () => router.back() }} />
      </View>
    );
  }

  const tracks: MusicTrack[] = pl.items.map((it) => mapServerItemToTrack({ name: it.name, path: it.path, root_id: it.root_id, extension: it.extension, mime: it.mime, size: it.size, modified: it.modified, is_dir: false } as any));

  const onPlayAll = () => { if (tracks.length) void playback.play(tracks[0], tracks); };

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <View style={s.header}>
        <Pressable onPress={() => router.back()} style={s.iconBtn}>
          <Ionicons name="arrow-back" size={18} color={colors.text} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text numberOfLines={1} style={s.title}>{pl.name}</Text>
          <Text style={s.meta}>{pl.items.length} tracks {pl.is_public ? "· Public" : ""} · {pl.owner_username ? `by ${pl.owner_username}` : ""}</Text>
        </View>
        <Pressable onPress={onPlayAll} style={s.playBtn}>
          <Ionicons name="play" size={18} color="#fff" />
        </Pressable>
      </View>
      {pl.description ? <Text style={s.desc}>{pl.description}</Text> : null}

      <View style={{ flex: 1 }}>
        <FlashList
          data={tracks}
          keyExtractor={(t) => t.id}
          
          renderItem={({ item }) => <TrackRow track={item} active={playback.current?.id === item.id} onPress={() => void playback.play(item, tracks)} />}
          ListEmptyComponent={<EmptyState title="Empty playlist" subtitle="Add tracks in the Nexora web app. Two-way sync lands in M3." />}
          contentContainerStyle={{ paddingBottom: 24 }}
        />
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  center: { flex: 1, backgroundColor: colors.bg, alignItems: "center", justifyContent: "center", padding: 16 },
  header: { flexDirection: "row", alignItems: "center", gap: 12, paddingHorizontal: 12, paddingTop: 10, paddingBottom: 8 },
  iconBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  title: { color: colors.text, fontSize: 16, fontWeight: "800" },
  meta: { color: colors.textMuted, fontSize: 11, marginTop: 2 },
  desc: { color: colors.textMuted, fontSize: 12, lineHeight: 16, paddingHorizontal: 16, paddingBottom: 10 },
  playBtn: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center" },
});