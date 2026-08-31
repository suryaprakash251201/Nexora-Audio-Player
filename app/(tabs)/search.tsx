import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, spacing } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { useSession } from "@/store/SessionContext";
import { usePlayback } from "@/store/PlaybackContext";
import { SearchBar } from "@/ui/SearchBar";
import { TrackRow } from "@/ui/TrackRow";
import { EmptyState } from "@/ui/EmptyState";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { Haptics } from "@/lib/haptics";
import { Toast } from "@/ui/Toast";
import type { MusicTrack } from "@/library/types";

function useDebounced<T>(value: T, ms = 250): T {
  const [v, setV] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setV(value), ms);
    return () => clearTimeout(id);
  }, [value, ms]);
  return v;
}

const MAX_HISTORY = 8;

export default function SearchScreen() {
  const lib = useLibrary();
  const { api } = useSession();
  const playback = usePlayback();
  const [query, setQuery] = useState("");
  const [history, setHistory] = useState<string[]>([]);
  const [serverResults, setServerResults] = useState<MusicTrack[]>([]);
  const [searching, setSearching] = useState(false);
  const debounced = useDebounced(query, 220);

  // Local search
  const localResults = useMemo(() => {
    const q = debounced.trim().toLowerCase();
    if (!q) return lib.tracks.slice(0, 60);
    return lib.tracks.filter((t) => {
      const hay = `${t.title} ${t.artist ?? ""} ${t.album ?? ""} ${t.albumArtist ?? ""} ${t.genre ?? ""} ${t.serverId?.path ?? ""}`.toLowerCase();
      return hay.includes(q);
    });
  }, [lib.tracks, debounced]);

  // Server-side search
  useEffect(() => {
    const q = debounced.trim();
    if (!q || !api) {
      setServerResults([]);
      return;
    }
    let cancelled = false;
    setSearching(true);
    api.search(q, { kind: "audio", limit: 50 })
      .then((res) => {
        if (cancelled) return;
        const mapped: MusicTrack[] = res.items
          .filter((item) => !lib.tracks.some((t) => t.serverId?.path === item.path && t.serverId?.rootId === item.root_id))
          .map((item) => ({
            id: `server:${item.root_id}:${item.path}`,
            source: "NEXORA_REMOTE" as const,
            serverId: { rootId: item.root_id, path: item.path },
            localId: null,
            title: item.name.replace(/\.[^.]+$/, ""),
            artist: null,
            album: null,
            albumArtist: null,
            genre: null,
            year: null,
            trackNumber: null,
            discNumber: null,
            metadata: {
              codec: item.extension?.toUpperCase() || "AUDIO",
              sampleRateHz: null,
              bitDepth: null,
              channels: null,
              bitrateKbps: null,
              durationSec: null,
              quality: null,
              replayGainTrackDb: null,
              replayGainAlbumDb: null,
              tags: {},
            },
            fileSize: item.size,
            localUri: null,
            streamUrl: null,
            artwork: { url: api.thumbnailUrl(item.root_id, item.path, 256), dominantColor: null },
            download: { state: "REMOTE" as const, progress: 0, errorMessage: null, localUri: null },
            favorite: false,
            modifiedAt: item.modified ?? null,
            lastPlayedAt: null,
            playCount: 0,
          }));
        setServerResults(mapped);
      })
      .catch(() => { if (!cancelled) setServerResults([]); })
      .finally(() => { if (!cancelled) setSearching(false); });
    return () => { cancelled = true; };
  }, [debounced, api, lib.tracks]);

  const allResults = useMemo(() => {
    if (!debounced.trim()) return localResults;
    return [...localResults, ...serverResults];
  }, [localResults, serverResults, debounced]);

  const onPlay = useCallback((t: MusicTrack) => {
    void playback.play(t, allResults);
    if (query.trim()) {
      setHistory((prev) => {
        const next = [query.trim(), ...prev.filter((h) => h !== query.trim())];
        return next.slice(0, MAX_HISTORY);
      });
    }
  }, [playback, allResults, query]);

  const onHistoryTap = (h: string) => {
    Haptics.tapLight();
    setQuery(h);
  };

  const clearHistory = () => {
    Haptics.tapMedium();
    setHistory([]);
    Toast.info("Search history cleared");
  };

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Discover"
        title="Search"
        subtitle={
          query
            ? `${allResults.length} match${allResults.length === 1 ? "" : "es"}${serverResults.length ? ` · ${serverResults.length} from server` : ""}`
            : `${lib.tracks.length.toLocaleString()} tracks indexed`
        }
      />
      <View style={{ paddingHorizontal: spacing.lg, paddingBottom: spacing.md }}>
        <SearchBar value={query} onChange={setQuery} placeholder="Tracks, albums, artists…" />
      </View>

      {/* Search history */}
      {!query.trim() && history.length > 0 ? (
        <View style={{ paddingHorizontal: spacing.lg, paddingBottom: spacing.md }}>
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
            <Text style={{ color: colors.textMuted, fontSize: 11, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase", fontFamily: font.sansBold }}>Recent searches</Text>
            <Pressable onPress={clearHistory} hitSlop={10}>
              <Text style={{ color: colors.textMuted, fontSize: 11, fontFamily: font.sansMedium }}>Clear</Text>
            </Pressable>
          </View>
          <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
            {history.map((h) => (
              <Pressable key={h} onPress={() => onHistoryTap(h)} style={styles.historyChip}>
                <Ionicons name="time-outline" size={12} color={colors.textMuted} />
                <Text style={styles.historyText}>{h}</Text>
              </Pressable>
            ))}
          </View>
        </View>
      ) : null}

      {/* Server search indicator */}
      {searching ? (
        <View style={{ paddingHorizontal: spacing.lg, paddingBottom: 6 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
            <Ionicons name="cloud-outline" size={12} color="#60A5FA" />
            <Text style={{ color: "#60A5FA", fontSize: 11, fontFamily: font.sansMedium }}>Searching Nexora server…</Text>
          </View>
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        <FlashList
          data={allResults}
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

const styles = StyleSheet.create({
  historyChip: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  historyText: { color: colors.textDim, fontSize: 12, fontFamily: font.sansMedium },
});