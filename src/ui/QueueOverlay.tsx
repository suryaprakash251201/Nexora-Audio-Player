import React, { useEffect, useMemo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { BlurView } from "expo-blur";
import { usePlayback } from "@/store/PlaybackContext";
import { useLibrary } from "@/store/LibraryContext";
import { colors, font, glass, motion, radius, spacing, tierColor } from "@/ui/theme";
import { GlassSurface } from "@/ui/Glass";
import { formatBitrate, formatSampleRate, formatBitDepth } from "@/audio/audioQuality";
import { cleanTrackTitle } from "@/lib/cleanTitle";
import { Haptics } from "@/lib/haptics";

/**
 * QueueOverlay — bottom-sheet-style panel showing the current playback
 * queue. Swipe to remove (M20). Tapping a row jumps to it.
 */
export default function QueueOverlay({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const playback = usePlayback();
  const lib = useLibrary();
  const insets = useSafeAreaInsets();

  if (!visible) return null;

  const items = playback.queue;
  const currentIndex = items.findIndex((t) => t.id === playback.current?.id);

  return (
    <View style={[s.backdrop, { paddingTop: insets.top + 12 }]} pointerEvents="box-none">
      {/* Defocus + dim the screen behind the sheet so the queue owns focus. */}
      <BlurView intensity={glass.blur.subtle} tint="dark" style={StyleSheet.absoluteFill} />
      <View pointerEvents="none" style={[StyleSheet.absoluteFill, s.dim]} />
      <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
      <GlassSurface variant="sheet" radius={0} border={false} style={[s.sheet, { paddingBottom: insets.bottom + 80 }]}>
        <View style={s.handle} />
        <View style={s.header}>
          <View>
            <Text style={s.kicker}>NOW PLAYING</Text>
            <Text style={s.title}>Queue · {items.length}</Text>
          </View>
          <View style={s.headerActions}>
            <Pressable onPress={() => { Haptics.tapLight(); playback.clearQueue(); }} style={s.headerBtn}>
              <Ionicons name="trash-outline" size={16} color={colors.textDim} />
              <Text style={s.headerBtnLabel}>Clear</Text>
            </Pressable>
            <Pressable onPress={onClose} style={s.closeBtn}>
              <Ionicons name="close" size={18} color={colors.text} />
            </Pressable>
          </View>
        </View>

        <FlashList
          data={items}
          keyExtractor={(t) => t.id}
          renderItem={({ item, index }) => {
            const isCurrent = index === currentIndex;
            const q = item.metadata.quality;
            const tier = (q?.tier ?? "standard") as keyof typeof tierColor;
            const tierC = tierColor[tier] ?? tierColor.mp3;
            return (
              <Pressable
                onPress={() => {
                  Haptics.tapLight();
                  void playback.play(item, items);
                }}
                onLongPress={() => {
                  Haptics.tapMedium();
                  void playback.removeFromQueue(item.id);
                }}
                style={[s.row, isCurrent && s.rowCurrent]}
              >
                <View style={s.rowArt}>
                  <Ionicons name="musical-note" size={16} color="rgba(255,255,255,0.8)" />
                </View>
                <View style={{ flex: 1, minWidth: 0 }}>
                  <Text numberOfLines={1} style={[s.rowTitle, isCurrent && { color: colors.accent }]}>
                    {cleanTrackTitle(item.title)}
                  </Text>
                  <Text numberOfLines={1} style={s.rowSub}>
                    {[item.artist, item.album].filter(Boolean).join(" · ") || item.serverId?.path || "Unknown"}
                  </Text>
                </View>
                <View style={s.rowBadges}>
                  {q?.bitDepth || q?.sampleRateKHz ? (
                    <Text style={s.mono}>
                      {[q?.bitDepth ? formatBitDepth(q.bitDepth) : null, q?.sampleRateKHz ? formatSampleRate(q.sampleRateKHz) : null]
                        .filter(Boolean)
                        .join(" · ")}
                    </Text>
                  ) : null}
                  <View style={[s.tierChip, { backgroundColor: tierC.soft }]}>
                    <Text style={[s.tierLabel, { color: tierC.accent }]}>{tierC.label}</Text>
                  </View>
                </View>
                <Pressable
                  onPress={() => {
                    Haptics.tapLight();
                    void playback.removeFromQueue(item.id);
                  }}
                  hitSlop={8}
                  style={s.removeBtn}
                >
                  <Ionicons name="remove" size={18} color={colors.textMuted} />
                </Pressable>
              </Pressable>
            );
          }}
          ListEmptyComponent={
            <View style={{ padding: 32, alignItems: "center" }}>
              <Text style={{ color: colors.textMuted, fontSize: 13 }}>Queue is empty</Text>
            </View>
          }
          contentContainerStyle={{ paddingBottom: 24 }}
        />
      </GlassSurface>
    </View>
  );
}

const s = StyleSheet.create({
  backdrop: { ...StyleSheet.absoluteFillObject, justifyContent: "flex-end" },
  /** Dim level behind the sheet (blur is provided by BlurView). */
  dim: { backgroundColor: "rgba(0,0,0,0.42)" },
  sheet: {
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    borderTopWidth: 1,
    borderTopColor: glass.edge.strong,
    maxHeight: "78%",
    paddingTop: 8,
  },
  handle: { alignSelf: "center", width: 40, height: 4, borderRadius: 2, backgroundColor: "rgba(255,255,255,0.18)", marginBottom: 10 },
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.lg, paddingBottom: spacing.md },
  kicker: { color: colors.textMuted, fontSize: 10, fontWeight: "700", letterSpacing: 1.4, fontFamily: font.sansMedium },
  title: { color: colors.text, fontSize: 18, fontWeight: "700", fontFamily: font.sansBold, marginTop: 2 },
  headerActions: { flexDirection: "row", gap: 8, alignItems: "center" },
  headerBtn: { flexDirection: "row", gap: 4, alignItems: "center", backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, paddingHorizontal: 10, height: 32, borderRadius: 8 },
  headerBtnLabel: { color: colors.textDim, fontSize: 11, fontFamily: font.sansSemibold },
  closeBtn: { width: 32, height: 32, borderRadius: 16, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  row: { flexDirection: "row", alignItems: "center", gap: 10, paddingHorizontal: spacing.lg, paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: "rgba(255,255,255,0.04)" },
  rowCurrent: { backgroundColor: "rgba(139,92,246,0.08)" },
  rowArt: { width: 38, height: 38, borderRadius: 8, backgroundColor: "#22222E", alignItems: "center", justifyContent: "center" },
  rowTitle: { color: colors.text, fontSize: 13, fontWeight: "600", fontFamily: font.sansSemibold },
  rowSub: { color: colors.textMuted, fontSize: 11, marginTop: 1 },
  rowBadges: { alignItems: "flex-end", gap: 4 },
  mono: { color: colors.textMuted, fontSize: 10, fontFamily: font.mono },
  tierChip: { paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4 },
  tierLabel: { fontSize: 9, fontWeight: "800", letterSpacing: 0.6, fontFamily: font.sansBold },
  removeBtn: { width: 28, height: 28, alignItems: "center", justifyContent: "center" },
});