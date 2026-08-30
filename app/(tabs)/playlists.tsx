import React, { useState } from "react";
import { Alert, Modal, Pressable, RefreshControl, StyleSheet, Text, TextInput, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { usePlaylists } from "@/store/PlaylistContext";
import { useSession } from "@/store/SessionContext";
import { EmptyState } from "@/ui/EmptyState";
import { router } from "expo-router";

function SyncPill({ status, pending }: { status: string; pending: number }) {
  const map: Record<string, { label: string; color: string }> = {
    idle: { label: "Synced", color: "#22C55E" },
    syncing: { label: pending ? `Syncing · ${pending} pending` : "Syncing", color: "#F5C451" },
    offline: { label: "Offline", color: "#8A8A8A" },
    conflict: { label: "Conflict", color: "#F87171" },
  };
  const cur = map[status] || map.idle;
  return (
    <View style={[styles.pill, { borderColor: cur.color, backgroundColor: `${cur.color}14` }]}>
      <View style={[styles.pillDot, { backgroundColor: cur.color }]} />
      <Text style={[styles.pillLabel, { color: cur.color }]}>{cur.label}</Text>
    </View>
  );
}

export default function PlaylistsScreen() {
  const { api } = useSession();
  const pl = usePlaylists();
  const [showCreate, setShowCreate] = useState(false);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");

  const onCreate = async () => {
    const trimmed = name.trim();
    if (!trimmed) return;
    await pl.create(trimmed, desc.trim());
    setName("");
    setDesc("");
    setShowCreate(false);
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <View style={styles.header}>
        <Text style={styles.title}>Playlists</Text>
        <View style={{ flexDirection: "row", gap: 8, alignItems: "center" }}>
          <SyncPill status={pl.syncStatus} pending={pl.pendingOps} />
          <Pressable onPress={() => void pl.refresh()} style={styles.iconBtn}>
            <Ionicons name="refresh" size={16} color={colors.textMuted} />
          </Pressable>
          <Pressable onPress={() => setShowCreate(true)} style={styles.createBtn}>
            <Ionicons name="add" size={16} color="#fff" />
            <Text style={styles.createLabel}>New</Text>
          </Pressable>
        </View>
      </View>

      {pl.conflicts.length ? (
        <View style={styles.conflictBox}>
          <Text style={styles.conflictTitle}>Sync conflict</Text>
          <Text style={styles.conflictBody}>A playlist was changed both locally and on the server. Choose how to resolve.</Text>
          {pl.conflicts.map((c) => (
            <View key={c.playlistId} style={styles.conflictRow}>
              <Text style={styles.conflictId} numberOfLines={1}>{c.playlistId.slice(0, 12)}…</Text>
              <Pressable onPress={() => void pl.resolveConflict(c.playlistId, "keep_mine")} style={[styles.cBtn, { backgroundColor: colors.accent }]}>
                <Text style={styles.cBtnLabel}>Keep mine</Text>
              </Pressable>
              <Pressable onPress={() => void pl.resolveConflict(c.playlistId, "keep_server")} style={[styles.cBtn, styles.cBtnGhost]}>
                <Text style={[styles.cBtnLabel, { color: colors.text }]}>Keep server</Text>
              </Pressable>
              <Pressable onPress={() => void pl.resolveConflict(c.playlistId, "merge")} style={[styles.cBtn, styles.cBtnGhost]}>
                <Text style={[styles.cBtnLabel, { color: colors.text }]}>Merge</Text>
              </Pressable>
            </View>
          ))}
        </View>
      ) : null}

      <View style={{ flex: 1 }}>
        <FlashList
          data={pl.playlists}
          keyExtractor={(p) => p.id}
          refreshControl={<RefreshControl refreshing={pl.loading} onRefresh={() => void pl.refresh()} tintColor={colors.text} />}
          renderItem={({ item }) => (
            <Pressable onPress={() => router.push({ pathname: "/playlist/[id]", params: { id: item.id } })} style={styles.card}>
              <View style={styles.cardArt}>
                <Ionicons name="list" size={20} color="rgba(255,255,255,0.9)" />
              </View>
              <View style={{ flex: 1, gap: 2 }}>
                <Text numberOfLines={1} style={styles.cardTitle}>{item.name}</Text>
                <Text style={styles.cardMeta}>{item.items.length} tracks {item.is_public ? "· Public" : ""}</Text>
                {item.description ? <Text numberOfLines={1} style={styles.cardDesc}>{item.description}</Text> : null}
              </View>
              <Pressable
                hitSlop={10}
                onPress={() => {
                  Alert.alert(item.name, "What would you like to do?", [
                    { text: "Cancel", style: "cancel" },
                    { text: "Rename", onPress: () => {
                      Alert.prompt?.("Rename", undefined, (newName) => { if (newName) void pl.rename(item.id, newName); }, "plain-text", item.name);
                    }},
                    { text: "Delete", style: "destructive", onPress: () => void pl.deletePlaylist(item.id) },
                  ]);
                }}
                style={{ width: 32, height: 32, alignItems: "center", justifyContent: "center" }}
              >
                <Ionicons name="ellipsis-horizontal" size={16} color={colors.textMuted} />
              </Pressable>
              <Ionicons name="chevron-forward" size={14} color={colors.textMuted} />
            </Pressable>
          )}
          ListHeaderComponent={
            !api ? (
              <View style={{ paddingHorizontal: 16, paddingTop: 8 }}>
                <View style={styles.offlineCard}>
                  <Text style={styles.offlineTitle}>Offline playlists</Text>
                  <Text style={styles.offlineBody}>Create and edit playlists offline — they queue and sync when you reconnect. You're currently not connected to Nexora.</Text>
                </View>
              </View>
            ) : (
              <View style={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 4 }}>
                <Text style={styles.hint}>Tap to open · long-press or … for rename/delete · pull to sync</Text>
              </View>
            )
          }
          ListEmptyComponent={
            pl.loading ? null : (
              <EmptyState
                title={api ? "No playlists yet" : "No playlists"}
                subtitle={api ? "Create one — it will sync to your Nexora." : "Playlists you create here will sync when you connect."}
                action={{ label: "New playlist", onPress: () => setShowCreate(true) }}
              />
            )
          }
          contentContainerStyle={{ paddingBottom: 24 }}
        />
      </View>

      <Modal visible={showCreate} transparent animationType="fade" onRequestClose={() => setShowCreate(false)}>
        <Pressable style={styles.modalOverlay} onPress={() => setShowCreate(false)}>
          <Pressable style={styles.modalCard} onPress={(e) => e.stopPropagation()}>
            <Text style={styles.modalTitle}>New playlist</Text>
            <TextInput value={name} onChangeText={setName} placeholder="My mix" placeholderTextColor={colors.textMuted} style={styles.input} autoFocus />
            <TextInput value={desc} onChangeText={setDesc} placeholder="Description (optional)" placeholderTextColor={colors.textMuted} style={styles.input} />
            <View style={{ flexDirection: "row", gap: 10, marginTop: 8 }}>
              <Pressable onPress={() => setShowCreate(false)} style={[styles.modalBtn, styles.modalGhost]}>
                <Text style={[styles.modalBtnLabel, { color: colors.text }]}>Cancel</Text>
              </Pressable>
              <Pressable onPress={() => void onCreate()} style={[styles.modalBtn, { backgroundColor: colors.accent }]}>
                <Text style={[styles.modalBtnLabel, { color: "#fff" }]}>Create</Text>
              </Pressable>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 16, paddingTop: 12, paddingBottom: 10, gap: 10 },
  title: { color: colors.text, fontSize: 20, fontWeight: "800" },
  iconBtn: { width: 34, height: 34, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  createBtn: { flexDirection: "row", gap: 4, alignItems: "center", backgroundColor: colors.accent, paddingHorizontal: 12, height: 34, borderRadius: 10 },
  createLabel: { color: "#fff", fontWeight: "800", fontSize: 13 },
  pill: { flexDirection: "row", alignItems: "center", gap: 6, borderWidth: 1, borderRadius: 8, paddingHorizontal: 8, height: 28 },
  pillDot: { width: 7, height: 7, borderRadius: 4 },
  pillLabel: { fontSize: 11, fontWeight: "800", letterSpacing: 0.4 },
  conflictBox: { marginHorizontal: 16, backgroundColor: "rgba(248,113,113,0.12)", borderWidth: 1, borderColor: "rgba(248,113,113,0.22)", borderRadius: 12, padding: 12, gap: 8, marginBottom: 8 },
  conflictTitle: { color: "#FECACA", fontWeight: "800", fontSize: 13 },
  conflictBody: { color: "#FECACA", fontSize: 11, lineHeight: 14 },
  conflictRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 4 },
  conflictId: { flex: 1, color: colors.textDim, fontSize: 11 },
  cBtn: { paddingHorizontal: 10, paddingVertical: 7, borderRadius: 8 },
  cBtnGhost: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline },
  cBtnLabel: { color: "#fff", fontWeight: "800", fontSize: 11 },
  card: { flexDirection: "row", alignItems: "center", gap: 12, marginHorizontal: 16, marginBottom: 10, backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, padding: 12 },
  cardArt: { width: 44, height: 44, borderRadius: 10, backgroundColor: "#2A2A3A", alignItems: "center", justifyContent: "center" },
  cardTitle: { color: colors.text, fontWeight: "700", fontSize: 14 },
  cardMeta: { color: colors.textMuted, fontSize: 11 },
  cardDesc: { color: colors.textMuted, fontSize: 11 },
  offlineCard: { backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, padding: 14, gap: 6 },
  offlineTitle: { color: colors.text, fontWeight: "800", fontSize: 13 },
  offlineBody: { color: colors.textMuted, fontSize: 12, lineHeight: 16 },
  hint: { color: colors.textMuted, fontSize: 11, textAlign: "center" },
  modalOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.55)", alignItems: "center", justifyContent: "center", padding: 20 },
  modalCard: { width: "100%", maxWidth: 420, backgroundColor: colors.bgRaised, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: colors.hairline, gap: 10 },
  modalTitle: { color: colors.text, fontWeight: "800", fontSize: 16 },
  input: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, borderRadius: 10, paddingHorizontal: 12, height: 42, color: colors.text, fontSize: 14 },
  modalBtn: { flex: 1, height: 42, borderRadius: 10, alignItems: "center", justifyContent: "center" },
  modalGhost: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline },
  modalBtnLabel: { fontWeight: "800", fontSize: 13 },
});