import React, { useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, accent, shadow } from "@/ui/theme";
import { Haptics } from "@/lib/haptics";

export function SearchBar({
  value,
  onChange,
  placeholder = "Search tracks, albums, artists…",
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  const [focused, setFocused] = useState(false);

  return (
    <View style={[styles.root, focused && styles.focused]}>
      <Ionicons name="search" size={18} color={focused ? accent.primary : colors.textMuted} />
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textMuted}
        style={styles.input}
        autoCorrect={false}
        autoCapitalize="none"
        returnKeyType="search"
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
      />
      {value ? (
        <Pressable
          onPress={() => {
            Haptics.tapLight();
            onChange("");
          }}
          hitSlop={10}
          style={styles.clearBtn}
        >
          <Ionicons name="close-circle" size={18} color={colors.textDim} />
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 14,
    height: 44,
    borderRadius: radius.md,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    ...shadow.sm,
  },
  focused: {
    borderColor: accent.primary,
    backgroundColor: "rgba(18,18,30,0.95)",
    ...shadow.glow(accent.primary, 0.3),
  },
  input: {
    flex: 1,
    color: colors.text,
    fontSize: 14,
    fontFamily: font.sansMedium,
    paddingVertical: 0,
  },
  clearBtn: {
    padding: 2,
  },
});