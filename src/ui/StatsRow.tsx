import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, shadow, tierColor, accent } from "@/ui/theme";
import { Haptics } from "@/lib/haptics";

/**
 * StatsRow — Audiophile Telemetry HUD tiles.
 */
export function StatsRow({
  nexora,
  device,
  offline,
  refreshing,
  onRefresh,
}: {
  nexora: number;
  device: number;
  offline: number;
  refreshing: boolean;
  onRefresh: () => void;
}) {
  return (
    <View style={styles.row}>
      <Stat label="Nexora" count={nexora} dot="#38BDF8" icon="cloud-outline" />
      <Stat label="Device" count={device} dot="#10B981" icon="phone-portrait-outline" />
      <Stat label="Offline" count={offline} dot="#FBBF24" icon="cloud-download-outline" />
      <Pressable
        onPress={() => {
          Haptics.tapLight();
          onRefresh();
        }}
        hitSlop={10}
        style={({ pressed }) => [styles.refresh, pressed && { opacity: 0.7, transform: [{ scale: 0.95 }] }]}
        accessibilityLabel="Refresh library"
      >
        <Ionicons name={refreshing ? "sync" : "refresh"} size={18} color={accent.primary} />
      </Pressable>
    </View>
  );
}

function Stat({ label, count, dot, icon }: { label: string; count: number; dot: string; icon: keyof typeof Ionicons.glyphMap }) {
  return (
    <View style={styles.stat}>
      <View style={styles.topBar}>
        <Ionicons name={icon} size={14} color={dot} />
        <View style={[styles.statDot, { backgroundColor: dot, ...shadow.glow(dot, 0.6) }]} />
      </View>
      <Text style={styles.statNum}>{count.toLocaleString()}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", gap: 10, alignItems: "stretch" },
  stat: {
    flex: 1,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    borderRadius: radius.lg,
    padding: 12,
    gap: 4,
    ...shadow.sm,
  },
  topBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  statNum: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "900",
    fontFamily: font.monoBold,
    letterSpacing: -0.5,
  },
  statLabel: {
    color: colors.textMuted,
    fontSize: 10,
    fontWeight: "800",
    letterSpacing: 0.8,
    textTransform: "uppercase",
    fontFamily: font.sansBold,
  },
  statDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  refresh: {
    width: 48,
    borderRadius: radius.lg,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    alignItems: "center",
    justifyContent: "center",
    ...shadow.sm,
  },
});