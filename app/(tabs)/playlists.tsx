import React, { useCallback, useEffect, useState } from "react";
import { Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { EmptyState } from "@/ui/EmptyState";
import { usePlayback } from "@/store/PlaybackContext";
import type { Playlist } from "@/api/types";
import { router } from "expo-router";

function PlaylistCard({ pl, onPress }: { pl: Playlist; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.card}>
      <View style={styles.cardArt}>
        <Ionicons name="list" size={22} color="rgba(255,255,255,0.9)" />
      </View>
      <View style={{ flex: 1, gap: 2 }}>
        <Text numberOfLines={1} style={styles.cardTitle}>{pl.name}</Text>
        <Text numberOfLines={1} style={styles.cardMeta}>{pl.items.length} tracks {pl.is_public ? "· Public" : ""}</Text>
        {pl.description ? <Text numberOfLines={1} style={styles.cardDesc}>{pl.description}</Text> : null}
      </View>
      <Ionicons name="chevron-forward" size={16} color={colors.textMuted} />
    </Pressable>
  );
}

export default function PlaylistsScreen() {
  const { api } = useSession();
  const playback = usePlayback();
  const [playlists, setPlaylists] = useState<Playlist[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    if (!api) { setPlaylists([]); return; }
    setLoading(true);
    try {
      const res = await api.listPlaylists();
      setPlaylists(res.items || []);
    } catch {
      // keep existing
    } finally {
      setLoading(false);
    }
  }, [api]);

  useEffect(() => { void refresh(); }, [refresh]);

  if (!api) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.bg }}>
        <View style={styles.header}><Text style={styles.title}>Playlists</Text></View>
        <EmptyState title="Connect to see playlists" subtitle="Your Nexora playlists sync here. Create, reorder and collaborate with the server." action={{ label: "Connect", onPress: () => router.push("/login") }} />
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <View style={styles.header}>
        <Text style={styles.title}>Playlists</Text>
        <Pressable onPress={() => void refresh()} style={styles.iconBtn}>
          <Ionicons name="refresh" size={18} color={colors.textMuted} />
        </Pressable>
      </View>

      <View style={{ flex: 1 }}>
        <FlashList
          data={playlists}
          keyExtractor={(p) => p.id}
          
          refreshControl={<RefreshControl refreshing={loading} onRefresh={() => void refresh()} tintColor={colors.text} />}
          renderItem={({ item }) => (
            <PlaylistCard
              pl={item}
              onPress={() => router.push({ pathname: "/playlist/[id]", params: { id: item.id } })}
            />
          )}
          ListEmptyComponent={
            loading ? null : <EmptyState title="No playlists yet" subtitle="Create one in the Nexora web app or here (M3 adds create/reorder/sync)." />
          }
          ListHeaderComponent={
            <View style={{ padding: 16, gap: 8 }}>
              <View style={styles.syncCard}>
                <Text style={styles.syncTitle}>Playlist sync</Text>
                <Text style={styles.syncBody}>Full two-way sync with conflict handling lands in M3. For now this is a read-only mirror of the server.</Text>
              </View>
            </View>
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
  card: { flexDirection: "row", alignItems: "center", gap: 12, marginHorizontal: 16, marginBottom: 10, backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, padding: 12 },
  cardArt: { width: 44, height: 44, borderRadius: 10, backgroundColor: "#2A2A3A", alignItems: "center", justifyContent: "center" },
  cardTitle: { color: colors.text, fontWeight: "700", fontSize: 14 },
  cardMeta: { color: colors.textMuted, fontSize: 11 },
  cardDesc: { color: colors.textMuted, fontSize: 11 },
  syncCard: { backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, padding: 14, gap: 6 },
  syncTitle: { color: colors.text, fontWeight: "800", fontSize: 13 },
  syncBody: { color: colors.textMuted, fontSize: 12, lineHeight: 16 },
});