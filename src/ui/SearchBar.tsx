import React from "react";
import { StyleSheet, TextInput } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { GlassSurface } from "@/ui/Glass";

export function SearchBar({
  value,
  onChange,
  placeholder = "Search tracks, albums, artists…",
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <GlassSurface variant="pill" radius={12} style={styles.root}>
      <Ionicons name="search" size={16} color={colors.textMuted} />
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textMuted}
        style={styles.input}
        autoCorrect={false}
        autoCapitalize="none"
        clearButtonMode="while-editing"
        returnKeyType="search"
      />
      {value ? <Ionicons name="close-circle" size={16} color={colors.textMuted} /> : null}
    </GlassSurface>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 12,
    height: 40,
  },
  input: { flex: 1, color: colors.text, fontSize: 14, paddingVertical: 0 },
});