import React, { useCallback, useEffect, useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { colors } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { SearchBar } from "@/ui/SearchBar";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import type { MusicTrack } from "@/library/types";

function useDebounced<T>(value: T, ms = 250): T {
  const [v, setV] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setV(value), ms);
    return () => clearTimeout(id);
  }, [value, ms]);
  return v;
}

export default function SearchScreen() {
  const lib = useLibrary();
  const playback = usePlayback();
  const [query, setQuery] = useState("");
  const debounced = useDebounced(query, 250);

  const results = useMemo(() => {
    const q = debounced.trim().toLowerCase();
    if (!q) return lib.tracks.slice(0, 50);
    return lib.tracks.filter((t) => {
      const hay = `${t.title} ${t.artist ?? ""} ${t.album ?? ""} ${t.albumArtist ?? ""} ${t.genre ?? ""} ${t.serverId?.path ?? ""}`.toLowerCase();
      return hay.includes(q);
    });
  }, [lib.tracks, debounced]);

  const onPlay = useCallback((t: MusicTrack) => { void playback.play(t, results); }, [playback, results]);

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <View style={styles.header}>
        <SearchBar value={query} onChange={setQuery} placeholder="Search tracks, albums, artists…" />
      </View>

      <View style={{ flex: 1 }}>
        <FlashList
          data={results}
          keyExtractor={(i) => i.id}
          
          renderItem={({ item }) => <TrackRow track={item} active={playback.current?.id === item.id} onPress={() => onPlay(item)} />}
          ListEmptyComponent={
            query.trim() ? (
              <EmptyState title="No results" subtitle={`No tracks match “${query.trim()}”.`} />
            ) : lib.tracks.length === 0 ? (
              <EmptyState title="Search your music" subtitle="Connect to Nexora or allow on-device access. Results appear as you type." />
            ) : null
          }
          contentContainerStyle={{ paddingBottom: 24 }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { paddingHorizontal: 16, paddingTop: 12, paddingBottom: 10 },
});