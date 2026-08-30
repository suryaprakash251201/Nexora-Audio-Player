import React from "react";
import { StyleSheet, Text, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";

export function EmptyState({
  icon = "musical-notes-outline",
  title,
  subtitle,
  action,
}: {
  icon?: keyof typeof Ionicons.glyphMap;
  title: string;
  subtitle?: string;
  action?: { label: string; onPress: () => void };
}) {
  return (
    <View style={styles.root}>
      <View style={styles.iconWrap}>
        <Ionicons name={icon} size={32} color={colors.text} />
      </View>
      <Text style={styles.title}>{title}</Text>
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      {action ? (
        <Pressable onPress={action.onPress} style={styles.btn}>
          <Text style={styles.btnLabel}>{action.label}</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { alignItems: "center", justifyContent: "center", paddingHorizontal: 32, paddingVertical: 40, gap: 10 },
  iconWrap: { width: 72, height: 72, borderRadius: 16, backgroundColor: "rgba(139,92,246,0.12)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: "rgba(139,92,246,0.18)" },
  title: { color: colors.text, fontSize: 16, fontWeight: "700", textAlign: "center" },
  subtitle: { color: colors.textMuted, fontSize: 13, textAlign: "center", lineHeight: 18 },
  btn: { marginTop: 8, backgroundColor: colors.accent, paddingHorizontal: 18, paddingVertical: 10, borderRadius: 10 },
  btnLabel: { color: "#fff", fontWeight: "800", fontSize: 13 },
});