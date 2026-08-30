import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { colors } from "@/ui/theme";

export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
}: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (v: T) => void;
}) {
  return (
    <View style={styles.root}>
      {options.map((o) => {
        const active = o.value === value;
        return (
          <Pressable
            key={o.value}
            onPress={() => onChange(o.value)}
            style={[styles.item, active && styles.active]}
          >
            <Text style={[styles.label, active && styles.labelActive]}>{o.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: 10,
    padding: 3,
    gap: 3,
  },
  item: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 7,
    borderRadius: 7,
  },
  active: { backgroundColor: colors.bgRaised, shadowColor: "#000", shadowOpacity: 0.2, shadowRadius: 6, elevation: 2 },
  label: { color: colors.textMuted, fontSize: 12, fontWeight: "600", letterSpacing: 0.3 },
  labelActive: { color: colors.text },
});