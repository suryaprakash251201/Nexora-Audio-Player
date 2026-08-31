import React from "react";
import { Pressable, StyleSheet, Text } from "react-native";
import { accent, colors } from "@/ui/theme";
import { GlassSurface } from "@/ui/Glass";

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
    <GlassSurface variant="pill" radius={10} sheen={false} style={styles.root}>
      {options.map((o) => {
        const active = o.value === value;
        return (
          <Pressable key={o.value} onPress={() => onChange(o.value)} style={styles.item}>
            {active ? (
              <GlassSurface
                variant="pill"
                radius={7}
                tint={accent.primarySoft}
                style={StyleSheet.absoluteFill}
              />
            ) : null}
            <Text style={[styles.label, active && styles.labelActive]}>{o.label}</Text>
          </Pressable>
        );
      })}
    </GlassSurface>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    padding: 3,
    gap: 3,
  },
  item: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 7,
    borderRadius: 7,
    overflow: "hidden",
  },
  label: { color: colors.textMuted, fontSize: 12, fontWeight: "600", letterSpacing: 0.3 },
  labelActive: { color: colors.text },
});
