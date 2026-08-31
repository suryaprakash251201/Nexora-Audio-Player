import React, { ReactNode } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, spacing, radius, accent, shadow } from "@/ui/theme";
import { useLayout } from "@/ui/layout";
import { Haptics } from "@/lib/haptics";

/**
 * PageHeader — Studio Top Chrome.
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
            {kicker ? (
              <View style={styles.kickerRow}>
                <View style={styles.kickerDot} />
                <Text style={styles.kicker}>{kicker}</Text>
              </View>
            ) : null}
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
    <Pressable
      onPress={() => {
        Haptics.tapLight();
        onPress();
      }}
      hitSlop={10}
      style={({ pressed }) => [styles.iconBtn, pressed && { opacity: 0.7, transform: [{ scale: 0.95 }] }]}
    >
      <Ionicons name="chevron-back" size={20} color={colors.text} />
    </Pressable>
  );
}

export function HeaderAction({
  icon,
  label,
  onPress,
  danger,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label?: string;
  onPress: () => void;
  danger?: boolean;
}) {
  return (
    <Pressable
      onPress={() => {
        Haptics.tapLight();
        onPress();
      }}
      hitSlop={10}
      style={({ pressed }) => [
        styles.iconBtn,
        label ? { width: "auto", paddingHorizontal: 12 } : {},
        danger ? { borderColor: "rgba(239,68,68,0.35)", backgroundColor: "rgba(239,68,68,0.12)" } : {},
        pressed && { opacity: 0.75, transform: [{ scale: 0.96 }] },
      ]}
    >
      <Ionicons name={icon} size={18} color={danger ? colors.danger : colors.text} />
      {label ? (
        <Text style={[styles.actionLabel, { color: danger ? colors.danger : colors.text }]}>{label}</Text>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  outer: {
    backgroundColor: colors.bg,
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.md,
  },
  inner: {
    alignSelf: "center",
    width: "100%",
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  kickerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 2,
  },
  kickerDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: accent.primary,
  },
  kicker: {
    color: accent.primary,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 1.5,
    textTransform: "uppercase",
    fontFamily: font.sansBold,
  },
  title: {
    color: colors.text,
    fontSize: 24,
    fontWeight: "900",
    fontFamily: font.sansBold,
    letterSpacing: -0.4,
  },
  subtitle: {
    color: colors.textMuted,
    fontSize: 12,
    fontFamily: font.sansMedium,
    marginTop: 2,
    lineHeight: 16,
  },
  iconBtn: {
    height: 38,
    minWidth: 38,
    borderRadius: radius.md,
    backgroundColor: "rgba(255,255,255,0.06)",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    flexDirection: "row",
    paddingHorizontal: 8,
  },
  actionLabel: {
    fontSize: 12,
    fontWeight: "700",
    fontFamily: font.sansBold,
    marginLeft: 6,
  },
});