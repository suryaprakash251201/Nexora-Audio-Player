import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, spacing } from "@/ui/theme";
import { Haptics } from "@/lib/haptics";

/**
 * StatsRow — the colorful stat tiles on the Home dashboard.
 * Uses semantic colors (Nexora blue, Device green, Offline amber) so users
 * instantly understand the source dots in the library list.
 */
export function StatsRow({
  nexora, device, offline, refreshing, onRefresh,
}: {
  nexora: number;
  device: number;
  offline: number;
  refreshing: boolean;
  onRefresh: () => void;
}) {
  return (
    <View style={styles.row}>
      <Stat label="Nexora" count={nexora} dot="#60A5FA" />
      <Stat label="On Device" count={device} dot="#22C55E" />
      <Stat label="Offline" count={offline} dot="#F5C451" />
      <Pressable
        onPress={() => { Haptics.tapLight(); onRefresh(); }}
        hitSlop={10}
        style={styles.refresh}
        accessibilityLabel="Refresh library"
      >
        <Ionicons name={refreshing ? "sync" : "refresh"} size={16} color={colors.textDim} />
      </Pressable>
    </View>
  );
}

function Stat({ label, count, dot }: { label: string; count: number; dot: string }) {
  return (
    <View style={[styles.stat]}>
      <Text style={styles.statNum}>{count.toLocaleString()}</Text>
      <Text style={styles.statLabel}>{label}</Text>
      <View style={[styles.statDot, { backgroundColor: dot }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", gap: 10, alignItems: "stretch" },
  stat: { flex: 1, backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, borderRadius: radius.md, padding: 12, gap: 2, position: "relative", overflow: "hidden" },
  statNum: { color: colors.text, fontSize: 22, fontWeight: "800", fontFamily: font.sansBold, letterSpacing: -0.4 },
  statLabel: { color: colors.textMuted, fontSize: 10, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase", fontFamily: font.sansMedium },
  statDot: { position: "absolute", right: 10, top: 10, width: 8, height: 8, borderRadius: 4 },
  refresh: { width: 44, height: 44, borderRadius: radius.md, backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, alignItems: "center", justifyContent: "center" },
});