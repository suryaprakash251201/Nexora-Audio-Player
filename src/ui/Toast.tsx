/**
 * Toast — small "X updated just now" / "Syncing…" pill that drops in at
 * the top of the screen and auto-dismisses. Replaces the ad-hoc inline
 * status text in the queue overlay and the sync banner. Uses
 * `Animated.View` with native driver; no fake state machines.
 */
import React, { useEffect, useRef } from "react";
import { Animated, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, radius, spacing } from "@/ui/theme";

export type ToastTone = "info" | "success" | "warn" | "danger" | "muted";

type Toast = {
  id: number;
  message: string;
  tone: ToastTone;
  icon?: keyof typeof Ionicons.glyphMap;
  duration?: number;
};

let _id = 0;
let _emit: ((t: Toast) => void) | null = null;

export const Toast = {
  show(message: string, tone: ToastTone = "info", opts?: { icon?: keyof typeof Ionicons.glyphMap; duration?: number }) {
    if (!_emit) return;
    _emit({ id: ++_id, message, tone, icon: opts?.icon, duration: opts?.duration ?? 2200 });
  },
  success(message: string) { this.show(message, "success", { icon: "checkmark-circle" }); },
  warn(message: string) { this.show(message, "warn", { icon: "warning", duration: 3000 }); },
  error(message: string) { this.show(message, "danger", { icon: "alert-circle", duration: 3200 }); },
  info(message: string) { this.show(message, "info", { icon: "information-circle" }); },
};

const TONE_BG: Record<ToastTone, { bg: string; border: string; fg: string; icon: string }> = {
  info:    { bg: "rgba(96,165,250,0.16)", border: "rgba(96,165,250,0.32)", fg: colors.text, icon: "#60A5FA" },
  success: { bg: "rgba(34,197,94,0.16)",  border: "rgba(34,197,94,0.32)",  fg: colors.text, icon: "#22C55E" },
  warn:    { bg: "rgba(245,196,81,0.16)", border: "rgba(245,196,81,0.32)", fg: colors.text, icon: "#F5C451" },
  danger:  { bg: "rgba(248,113,113,0.18)", border: "rgba(248,113,113,0.32)", fg: colors.text, icon: "#F87171" },
  muted:   { bg: "rgba(138,138,154,0.16)", border: "rgba(138,138,154,0.32)", fg: colors.text, icon: colors.textMuted },
};

export function ToastHost() {
  const insets = useSafeAreaInsets();
  const [items, setItems] = React.useState<Toast[]>([]);
  const slide = useRef(new Animated.Value(-100)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    _emit = (t: Toast) => {
      setItems((prev) => [...prev.slice(-2), t]);
    };
    return () => { _emit = null; };
  }, []);

  useEffect(() => {
    if (items.length === 0) return;
    Animated.parallel([
      Animated.timing(slide, { toValue: 0, duration: 240, useNativeDriver: true }),
      Animated.timing(opacity, { toValue: 1, duration: 240, useNativeDriver: true }),
    ]).start();
    const last = items[items.length - 1];
    const id = setTimeout(() => {
      Animated.parallel([
        Animated.timing(slide, { toValue: -100, duration: 200, useNativeDriver: true }),
        Animated.timing(opacity, { toValue: 0, duration: 200, useNativeDriver: true }),
      ]).start(() => {
        setItems((prev) => prev.filter((x) => x.id !== last.id));
      });
    }, last.duration ?? 2200);
    return () => clearTimeout(id);
  }, [items, opacity, slide]);

  if (items.length === 0) return null;
  const last = items[items.length - 1];
  const t = TONE_BG[last.tone];

  return (
    <View pointerEvents="none" style={[styles.host, { paddingTop: insets.top + 8 }]}>
      <Animated.View style={[styles.pill, { backgroundColor: t.bg, borderColor: t.border, transform: [{ translateY: slide }], opacity }]}>
        <Ionicons name={last.icon ?? "information-circle"} size={16} color={t.icon} />
        <Text style={[styles.text, { color: t.fg }]} numberOfLines={2}>{last.message}</Text>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  host: { position: "absolute", top: 0, left: 0, right: 0, alignItems: "center", zIndex: 9999 },
  pill: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 14, paddingVertical: 10, borderRadius: radius.pill, borderWidth: 1, maxWidth: 520, minWidth: 200 },
  text: { fontSize: 13, fontWeight: "700", fontFamily: font.sansSemibold, flexShrink: 1 },
});