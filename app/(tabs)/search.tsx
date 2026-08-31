import React, { useCallback, useEffect, useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, spacing } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { usePlayback } from "@/store/PlaybackContext";
import { SearchBar } from "@/ui/SearchBar";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
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
  const debounced = useDebounced(query, 220);

  const results = useMemo(() => {
    const q = debounced.trim().toLowerCase();
    if (!q) return lib.tracks.slice(0, 60);
    return lib.tracks.filter((t) => {
      const hay = `${t.title} ${t.artist ?? ""} ${t.album ?? ""} ${t.albumArtist ?? ""} ${t.genre ?? ""} ${t.serverId?.path ?? ""}`.toLowerCase();
      return hay.includes(q);
    });
  }, [lib.tracks, debounced]);

  const onPlay = useCallback((t: MusicTrack) => { void playback.play(t, results); }, [playback, results]);

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Discover"
        title="Search"
        subtitle={query ? `${results.length} match${results.length === 1 ? "" : "es"}` : `${lib.tracks.length.toLocaleString()} tracks indexed`}
      />
      <View style={{ paddingHorizontal: spacing.lg, paddingBottom: spacing.md }}>
        <SearchBar value={query} onChange={setQuery} placeholder="Tracks, albums, artists…" />
      </View>
      <View style={{ flex: 1 }}>
        <FlashList
          data={results}
          keyExtractor={(i) => i.id}
          renderItem={({ item }) => <TrackRow track={item} active={playback.current?.id === item.id} onPress={() => onPlay(item)} />}
          ListEmptyComponent={
            query.trim() ? (
              <EmptyState icon="search" title="No matches" subtitle={`No tracks match “${query.trim()}”.`} />
            ) : lib.tracks.length === 0 ? (
              <EmptyState icon="search" title="Search your music" subtitle="Connect to Nexora or allow on-device access. Results appear as you type." />
            ) : null
          }
          contentContainerStyle={{ paddingBottom: 120 }}
          keyboardShouldPersistTaps="handled"
        />
      </View>
    </Container>
  );
}