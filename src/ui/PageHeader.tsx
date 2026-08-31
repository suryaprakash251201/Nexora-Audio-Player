import React, { ReactNode } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, spacing } from "@/ui/theme";
import { useLayout } from "@/ui/layout";
import { Haptics } from "@/lib/haptics";

/**
 * PageHeader — consistent top-of-screen chrome. Replaces the ad-hoc
 * `header` styles scattered across every screen. Adds a safe-area top
 * inset, a kicker, a title, optional subtitle, and optional left/right
 * action buttons.
 */
export function PageHeader({
  title,
  subtitle,
  kicker,
  left,
  right,
  border = true,
}: {
  title: string;
  subtitle?: string;
  kicker?: string;
  left?: ReactNode;
  right?: ReactNode;
  border?: boolean;
}) {
  const { contentMaxWidth } = useLayout();
  const insets = useSafeAreaInsets();
  return (
    <View
      style={[
        styles.outer,
        { paddingTop: insets.top + 8, borderBottomWidth: border ? 1 : 0, borderBottomColor: colors.hairline },
      ]}
    >
      <View style={[styles.inner, { maxWidth: contentMaxWidth }]}>
        <View style={styles.row}>
          {left}
          <View style={{ flex: 1 }}>
            {kicker ? <Text style={styles.kicker}>{kicker}</Text> : null}
            <Text numberOfLines={1} style={styles.title}>{title}</Text>
            {subtitle ? <Text numberOfLines={2} style={styles.subtitle}>{subtitle}</Text> : null}
          </View>
          {right}
        </View>
      </View>
    </View>
  );
}

/** Standard "back" button used by PageHeader. */
export function HeaderBack({ onPress }: { onPress: () => void }) {
  return (
    <Pressable onPress={() => { Haptics.tapLight(); onPress(); }} hitSlop={10} style={styles.iconBtn}>
      <Ionicons name="chevron-back" size={20} color={colors.text} />
    </Pressable>
  );
}

export function HeaderAction({ icon, label, onPress, danger }: { icon: keyof typeof Ionicons.glyphMap; label?: string; onPress: () => void; danger?: boolean }) {
  return (
    <Pressable onPress={() => { Haptics.tapLight(); onPress(); }} hitSlop={10} style={styles.iconBtn}>
      <Ionicons name={icon} size={18} color={danger ? colors.danger : colors.text} />
      {label ? <Text style={{ color: danger ? colors.danger : colors.text, fontSize: 12, fontWeight: "700", marginLeft: 6 }}>{label}</Text> : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  outer: { backgroundColor: colors.bg, paddingHorizontal: spacing.lg, paddingBottom: spacing.md },
  inner: { alignSelf: "center", width: "100%" },
  row: { flexDirection: "row", alignItems: "center", gap: 12 },
  kicker: { color: colors.textMuted, fontSize: 10, fontWeight: "800", letterSpacing: 1.4, textTransform: "uppercase", fontFamily: font.sansMedium },
  title: { color: colors.text, fontSize: 22, fontWeight: "800", fontFamily: font.sansBold, marginTop: 2 },
  subtitle: { color: colors.textMuted, fontSize: 12, fontFamily: font.sansRegular, marginTop: 2, lineHeight: 16 },
  iconBtn: { width: 36, height: 36, borderRadius: 12, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline, flexDirection: "row", paddingHorizontal: 8 },
});