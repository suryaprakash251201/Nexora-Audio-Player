import React, { useState } from "react";
import { Alert, Modal, Pressable, RefreshControl, StyleSheet, Text, TextInput, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, radius, spacing } from "@/ui/theme";
import { usePlaylists } from "@/store/PlaylistContext";
import { useSession } from "@/store/SessionContext";
import { EmptyState } from "@/ui/EmptyState";
import { PageHeader, HeaderAction } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { Toast } from "@/ui/Toast";
import { Haptics } from "@/lib/haptics";
import { router } from "expo-router";
import type { Playlist } from "@/api/types";

function SyncPill({ status, pending }: { status: string; pending: number }) {
  const map: Record<string, { label: string; color: string; icon: keyof typeof Ionicons.glyphMap }> = {
    idle:     { label: "Synced",                color: "#22C55E", icon: "checkmark-circle" },
    syncing:  { label: pending ? `Syncing · ${pending}` : "Syncing", color: "#F5C451", icon: "sync" },
    offline:  { label: "Offline",                color: "#8A8A9A", icon: "cloud-offline" },
    conflict: { label: "Conflict",               color: "#F87171", icon: "alert-circle" },
  };
  const cur = map[status] || map.idle;
  return (
    <View style={[styles.pill, { borderColor: cur.color, backgroundColor: `${cur.color}18` }]}>
      <Ionicons name={cur.icon} size={12} color={cur.color} />
      <Text style={[styles.pillLabel, { color: cur.color }]}>{cur.label}</Text>
    </View>
  );
}

function PlaylistCard({ pl, onPress, onMore }: { pl: Playlist; onPress: () => void; onMore: () => void }) {
  return (
    <Pressable onPress={() => { Haptics.tapLight(); onPress(); }} style={styles.card}>
      <View style={styles.cardArt}>
        <Ionicons name="list" size={22} color="rgba(255,255,255,0.9)" />
      </View>
      <View style={{ flex: 1, gap: 2, minWidth: 0 }}>
        <Text numberOfLines={1} style={styles.cardTitle}>{pl.name}</Text>
        <Text style={styles.cardMeta}>{pl.items.length} tracks {pl.is_public ? "· Public" : ""}</Text>
        {pl.description ? <Text numberOfLines={1} style={styles.cardDesc}>{pl.description}</Text> : null}
      </View>
      <Pressable onPress={(e) => { e.stopPropagation?.(); Haptics.tapLight(); onMore(); }} hitSlop={10} style={styles.moreBtn} accessibilityLabel="Playlist actions">
        <Ionicons name="ellipsis-horizontal" size={16} color={colors.textMuted} />
      </Pressable>
    </Pressable>
  );
}

export default function PlaylistsScreen() {
  const { api } = useSession();
  const pl = usePlaylists();
  const insets = useSafeAreaInsets();
  const [showCreate, setShowCreate] = useState(false);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");

  const onCreate = async () => {
    const trimmed = name.trim();
    if (!trimmed) return;
    try {
      await pl.create(trimmed, desc.trim());
      Toast.success(`Playlist “${trimmed}” created`);
      setName(""); setDesc(""); setShowCreate(false);
    } catch (e: any) { Toast.error(e?.message || "Could not create playlist"); }
  };

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Sync"
        title="Playlists"
        subtitle={api ? `${pl.playlists.length} playlist${pl.playlists.length === 1 ? "" : "s"}` : "Offline playlists queue and sync when you connect"}
        right={
          <View style={{ flexDirection: "row", gap: 8, alignItems: "center" }}>
            <HeaderAction icon="add" label="New" onPress={() => { Haptics.tapLight(); setShowCreate(true); }} />
          </View>
        }
      />

      <View style={{ paddingHorizontal: spacing.lg, paddingBottom: spacing.md, flexDirection: "row", alignItems: "center", gap: 10 }}>
        <SyncPill status={pl.syncStatus} pending={pl.pendingOps} />
        <Pressable onPress={() => { Haptics.tapLight(); void pl.refresh(); }} hitSlop={10} style={styles.refresh} accessibilityLabel="Sync playlists">
          <Ionicons name="sync" size={16} color={colors.textMuted} />
        </Pressable>
      </View>

      {pl.conflicts.length ? (
        <View style={styles.conflictBox}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
            <Ionicons name="alert-circle" size={16} color="#F87171" />
            <Text style={styles.conflictTitle}>Sync conflict</Text>
          </View>
          <Text style={styles.conflictBody}>A playlist was changed both locally and on the server. Choose how to resolve.</Text>
          {pl.conflicts.map((c) => (
            <View key={c.playlistId} style={styles.conflictRow}>
              <Text style={styles.conflictId} numberOfLines={1}>Playlist {c.playlistId.slice(0, 8)}…</Text>
              <Pressable onPress={() => { Haptics.tapMedium(); void pl.resolveConflict(c.playlistId, "keep_mine"); }} style={[styles.cBtn, { backgroundColor: colors.accent }]}>
                <Text style={styles.cBtnLabel}>Keep mine</Text>
              </Pressable>
              <Pressable onPress={() => { Haptics.tapMedium(); void pl.resolveConflict(c.playlistId, "keep_server"); }} style={[styles.cBtn, styles.cBtnGhost]}>
                <Text style={[styles.cBtnLabel, { color: colors.text }]}>Server</Text>
              </Pressable>
              <Pressable onPress={() => { Haptics.tapMedium(); void pl.resolveConflict(c.playlistId, "merge"); }} style={[styles.cBtn, styles.cBtnGhost]}>
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
            <PlaylistCard
              pl={item}
              onPress={() => router.push({ pathname: "/playlist/[id]", params: { id: item.id } })}
              onMore={() => {
                Alert.alert(item.name, undefined, [
                  { text: "Cancel", style: "cancel" },
                  { text: "Rename", onPress: () => { Alert.prompt?.("Rename", undefined, (newName) => { if (newName) void pl.rename(item.id, newName); }, "plain-text", item.name); } },
                  { text: "Delete", style: "destructive", onPress: () => {
                    Alert.alert("Delete playlist?", `“${item.name}” will be removed on the server.`, [
                      { text: "Cancel", style: "cancel" },
                      { text: "Delete", style: "destructive", onPress: () => void pl.deletePlaylist(item.id) },
                    ]);
                  } },
                ]);
              }}
            />
          )}
          ListEmptyComponent={
            pl.loading ? null : (
              <EmptyState
                icon="list"
                title={api ? "No playlists yet" : "No playlists"}
                subtitle={api ? "Create one — it will sync to your Nexora." : "Playlists you create here will sync when you connect."}
                action={{ label: "New playlist", onPress: () => setShowCreate(true) }}
              />
            )
          }
          contentContainerStyle={{ paddingBottom: 120, paddingHorizontal: spacing.lg }}
        />
      </View>

      <Modal visible={showCreate} transparent animationType="fade" onRequestClose={() => setShowCreate(false)}>
        <Pressable style={styles.modalOverlay} onPress={() => setShowCreate(false)}>
          <Pressable style={[styles.modalCard, { paddingBottom: insets.bottom + 16 }]} onPress={(e) => e.stopPropagation()}>
            <Text style={styles.modalTitle}>New playlist</Text>
            <Text style={styles.modalLabel}>Name</Text>
            <TextInput value={name} onChangeText={setName} placeholder="My mix" placeholderTextColor={colors.textMuted} style={styles.input} autoFocus />
            <Text style={styles.modalLabel}>Description (optional)</Text>
            <TextInput value={desc} onChangeText={setDesc} placeholder="Loud, lively, late-night…" placeholderTextColor={colors.textMuted} style={styles.input} />
            <View style={{ flexDirection: "row", gap: 10, marginTop: 10 }}>
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
    </Container>
  );
}

const styles = StyleSheet.create({
  refresh: { width: 32, height: 32, borderRadius: 10, backgroundColor: colors.card, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  pill: { flexDirection: "row", alignItems: "center", gap: 6, borderWidth: 1, borderRadius: 999, paddingHorizontal: 10, height: 28 },
  pillLabel: { fontSize: 11, fontWeight: "800", letterSpacing: 0.4, fontFamily: font.sansBold },
  conflictBox: { marginHorizontal: spacing.lg, marginBottom: spacing.md, backgroundColor: "rgba(248,113,113,0.12)", borderWidth: 1, borderColor: "rgba(248,113,113,0.32)", borderRadius: radius.lg, padding: 14, gap: 8 },
  conflictTitle: { color: "#FECACA", fontWeight: "800", fontSize: 13, fontFamily: font.sansBold },
  conflictBody: { color: "#FECACA", fontSize: 11, lineHeight: 16, fontFamily: font.sansRegular },
  conflictRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 6, flexWrap: "wrap" },
  conflictId: { width: "100%", color: colors.textDim, fontSize: 11, fontFamily: font.sansSemibold, marginBottom: 4 },
  cBtn: { paddingHorizontal: 10, paddingVertical: 7, borderRadius: 8 },
  cBtnGhost: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline },
  cBtnLabel: { color: "#fff", fontWeight: "800", fontSize: 11, fontFamily: font.sansBold },
  card: { flexDirection: "row", alignItems: "center", gap: 12, marginBottom: 10, backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, borderRadius: radius.md, padding: 12 },
  cardArt: { width: 48, height: 48, borderRadius: 12, backgroundColor: "rgba(139,92,246,0.18)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: "rgba(139,92,246,0.32)" },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 14, fontFamily: font.sansBold },
  cardMeta: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansMedium, fontWeight: "600" },
  cardDesc: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular },
  moreBtn: { width: 32, height: 32, alignItems: "center", justifyContent: "center" },
  modalOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.55)", alignItems: "center", justifyContent: "center", padding: 20 },
  modalCard: { width: "100%", maxWidth: 460, backgroundColor: colors.card, borderRadius: radius.lg, padding: 16, borderWidth: 1, borderColor: colors.hairline, gap: 8 },
  modalTitle: { color: colors.text, fontWeight: "800", fontSize: 18, fontFamily: font.sansBold, marginBottom: 4 },
  modalLabel: { color: colors.textMuted, fontSize: 10, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase", fontFamily: font.sansBold, marginTop: 4 },
  input: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, paddingHorizontal: 12, height: 44, color: colors.text, fontSize: 14, fontFamily: font.sansRegular },
  modalBtn: { flex: 1, height: 46, borderRadius: 12, alignItems: "center", justifyContent: "center" },
  modalGhost: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline },
  modalBtnLabel: { fontWeight: "800", fontSize: 13, fontFamily: font.sansBold },
});