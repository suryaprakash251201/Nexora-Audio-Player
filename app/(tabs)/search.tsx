import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
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

  const [category, setCategory] = useState("All");
  
  const allResults = useMemo(() => {
    let results = [...localResults];
    if (debounced.trim()) {
      results = [...results, ...serverResults];
    }
    
    if (category === "Tracks") return results;
    if (category === "Albums") return results.filter(t => t.album?.toLowerCase().includes(debounced.toLowerCase()));
    if (category === "Artists") return results.filter(t => (t.artist || t.albumArtist)?.toLowerCase().includes(debounced.toLowerCase()));
    if (category === "Folders") return results.filter(t => t.serverId?.path?.toLowerCase().includes(debounced.toLowerCase()));
    
    return results;
  }, [localResults, serverResults, debounced, category]);

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

  const categories = ["All", "Tracks", "Albums", "Artists", "Folders"];

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
      <View style={{ paddingHorizontal: spacing.lg, paddingBottom: 8 }}>
        <SearchBar value={query} onChange={setQuery} placeholder="Tracks, albums, artists…" />
      </View>
      
      <View style={{ paddingBottom: spacing.md }}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: spacing.lg, gap: 8 }}>
          {categories.map(c => {
            const active = category === c;
            return (
              <Pressable
                key={c}
                onPress={() => {
                  Haptics.selection();
                  setCategory(c);
                }}
                style={[styles.categoryChip, active && styles.categoryChipActive]}
              >
                <Text style={[styles.categoryChipText, active && styles.categoryChipTextActive]}>{c}</Text>
              </Pressable>
            );
          })}
        </ScrollView>
      </View>

      {/* Search history */}
      {!query.trim() && history.length > 0 ? (
        <View style={{ paddingHorizontal: spacing.lg, paddingBottom: spacing.md }}>
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
            <Text style={{ color: colors.textMuted, fontSize: 11, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase", fontFamily: font.sansBold }}>Recent searches</Text>
          </View>
          <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
            {history.map((h) => (
              <Pressable key={h} onPress={() => onHistoryTap(h)} style={styles.historyChip}>
                <Ionicons name="time-outline" size={12} color={colors.textMuted} />
                <Text style={styles.historyText}>{h}</Text>
              </Pressable>
            ))}
          </View>
          <Pressable onPress={clearHistory} style={styles.clearBtn} hitSlop={10}>
            <Ionicons name="trash-outline" size={14} color="#F87171" />
            <Text style={styles.clearBtnText}>Clear recent searches</Text>
          </Pressable>
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
  categoryChip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: "rgba(255,255,255,0.05)",
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  categoryChipActive: {
    backgroundColor: "rgba(139,92,246,0.15)",
    borderColor: "#8B5CF6",
  },
  categoryChipText: {
    color: colors.textDim,
    fontSize: 13,
    fontFamily: font.sansMedium,
  },
  categoryChipTextActive: {
    color: "#8B5CF6",
    fontFamily: font.sansBold,
  },
  clearBtn: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "flex-start",
    gap: 6,
    marginTop: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: "rgba(248,113,113,0.1)",
    borderWidth: 1,
    borderColor: "rgba(248,113,113,0.2)",
  },
  clearBtnText: {
    color: "#F87171",
    fontSize: 12,
    fontFamily: font.sansMedium,
  }
});