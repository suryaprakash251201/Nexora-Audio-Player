import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { colors } from "@/ui/theme";

export function Section({
  title,
  count,
  subtitle,
  action,
  children,
}: {
  title: string;
  count?: number;
  subtitle?: string;
  action?: { label: string; onPress: () => void };
  children: React.ReactNode;
}) {
  return (
    <View style={styles.root}>
      <View style={styles.header}>
        <View style={{ gap: 2, flex: 1 }}>
          <Text style={styles.title}>
            {title}
            {count != null ? <Text style={styles.count}>  ·  {count}</Text> : null}
          </Text>
          {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
        </View>
        {action ? (
          <Pressable onPress={action.onPress} hitSlop={8}>
            <Text style={styles.action}>{action.label}</Text>
          </Pressable>
        ) : null}
      </View>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { gap: 10, paddingTop: 8 },
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 16 },
  title: { color: colors.text, fontSize: 13, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase" },
  subtitle: { color: colors.textMuted, fontSize: 11, fontWeight: "500", marginTop: 2 },
  count: { color: colors.textMuted, fontWeight: "600" },
  action: { color: colors.accent, fontSize: 12, fontWeight: "700" },
});