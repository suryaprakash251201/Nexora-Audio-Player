import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { router } from "expo-router";

export function ConnectBanner({ compact }: { compact?: boolean }) {
  return (
    <View style={[styles.root, compact && styles.compact]}>
      <View style={styles.icon}>
        <Ionicons name="cloud-outline" size={18} color="#fff" />
      </View>
      <View style={{ flex: 1, gap: 2 }}>
        <Text style={styles.title}>Connect to Nexora</Text>
        <Text style={styles.subtitle}>Add your server URL to browse your music library</Text>
      </View>
      <Pressable onPress={() => router.push("/login")} style={styles.btn}>
        <Text style={styles.btnLabel}>Connect</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    margin: 16,
    padding: 14,
    borderRadius: 14,
    backgroundColor: "rgba(139,92,246,0.12)",
    borderWidth: 1,
    borderColor: "rgba(139,92,246,0.22)",
  },
  compact: { margin: 12, padding: 12 },
  icon: { width: 36, height: 36, borderRadius: 10, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center" },
  title: { color: colors.text, fontWeight: "800", fontSize: 13 },
  subtitle: { color: colors.textMuted, fontSize: 12 },
  btn: { backgroundColor: colors.accent, paddingHorizontal: 14, paddingVertical: 8, borderRadius: 8 },
  btnLabel: { color: "#fff", fontWeight: "800", fontSize: 12 },
});