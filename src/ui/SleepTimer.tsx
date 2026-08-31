import React, { useCallback, useEffect, useRef, useState } from "react";
import { Modal, Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, radius } from "@/ui/theme";
import { usePlayback } from "@/store/PlaybackContext";
import { Haptics } from "@/lib/haptics";
import { Toast } from "@/ui/Toast";

const PRESETS = [
  { label: "5 min", minutes: 5 },
  { label: "10 min", minutes: 10 },
  { label: "15 min", minutes: 15 },
  { label: "30 min", minutes: 30 },
  { label: "45 min", minutes: 45 },
  { label: "1 hour", minutes: 60 },
  { label: "1.5 hours", minutes: 90 },
  { label: "End of track", minutes: -1 },
];

export function SleepTimerModal({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const playback = usePlayback();
  const insets = useSafeAreaInsets();
  const [remaining, setRemaining] = useState<number | null>(null);
  const [endOfTrack, setEndOfTrack] = useState(false);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const endRef = useRef<number | null>(null);

  const clearTimer = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current);
    timerRef.current = null;
    endRef.current = null;
    setRemaining(null);
    setEndOfTrack(false);
  }, []);

  const startTimer = useCallback((minutes: number) => {
    Haptics.tapMedium();
    clearTimer();

    if (minutes === -1) {
      setEndOfTrack(true);
      Toast.info("Sleep timer: end of current track");
      onClose();
      return;
    }

    const endMs = Date.now() + minutes * 60 * 1000;
    endRef.current = endMs;
    setRemaining(minutes * 60);

    timerRef.current = setInterval(() => {
      const left = Math.max(0, Math.ceil((endMs - Date.now()) / 1000));
      setRemaining(left);
      if (left <= 0) {
        void playback.pause();
        clearTimer();
        Toast.info("Sleep timer ended — playback paused");
      }
    }, 1000);

    Toast.info(`Sleep timer set for ${minutes} minutes`);
    onClose();
  }, [clearTimer, onClose, playback]);

  useEffect(() => {
    if (!endOfTrack) return;
    const check = setInterval(() => {
      if (!playback.playing) {
        setEndOfTrack(false);
        clearInterval(check);
      }
    }, 1000);
    return () => clearInterval(check);
  }, [endOfTrack, playback.playing]);

  useEffect(() => {
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, []);

  const fmtRemaining = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}:${String(s).padStart(2, "0")}`;
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable style={[styles.card, { paddingBottom: insets.bottom + 16 }]} onPress={(e) => e.stopPropagation()}>
          <View style={styles.header}>
            <Ionicons name="moon-outline" size={22} color={colors.accent} />
            <Text style={styles.title}>Sleep Timer</Text>
          </View>

          {remaining !== null ? (
            <View style={styles.activeBox}>
              <Text style={styles.activeTime}>{fmtRemaining(remaining)}</Text>
              <Text style={styles.activeLabel}>remaining</Text>
              <Pressable onPress={() => { Haptics.tapMedium(); clearTimer(); Toast.info("Sleep timer cancelled"); onClose(); }} style={styles.cancelBtn}>
                <Ionicons name="close" size={14} color="#FCA5A5" />
                <Text style={styles.cancelLabel}>Cancel timer</Text>
              </Pressable>
            </View>
          ) : endOfTrack ? (
            <View style={styles.activeBox}>
              <Ionicons name="musical-note" size={24} color={colors.accent} />
              <Text style={styles.activeLabel}>Pausing after current track</Text>
              <Pressable onPress={() => { Haptics.tapMedium(); clearTimer(); Toast.info("Sleep timer cancelled"); onClose(); }} style={styles.cancelBtn}>
                <Ionicons name="close" size={14} color="#FCA5A5" />
                <Text style={styles.cancelLabel}>Cancel</Text>
              </Pressable>
            </View>
          ) : (
            <View style={styles.grid}>
              {PRESETS.map((p) => (
                <Pressable key={p.minutes} onPress={() => startTimer(p.minutes)} style={styles.preset}>
                  <Text style={styles.presetLabel}>{p.label}</Text>
                </Pressable>
              ))}
            </View>
          )}
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.55)", alignItems: "center", justifyContent: "center", padding: 20 },
  card: { width: "100%", maxWidth: 400, backgroundColor: colors.card, borderRadius: radius.lg, padding: 20, borderWidth: 1, borderColor: colors.hairline, gap: 16 },
  header: { flexDirection: "row", alignItems: "center", gap: 10 },
  title: { color: colors.text, fontWeight: "800", fontSize: 18, fontFamily: font.sansBold },
  grid: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  preset: { width: "47%", backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, paddingVertical: 14, alignItems: "center" },
  presetLabel: { color: colors.text, fontWeight: "700", fontSize: 14, fontFamily: font.sansSemibold },
  activeBox: { alignItems: "center", gap: 8, paddingVertical: 12 },
  activeTime: { color: colors.accent, fontSize: 48, fontWeight: "800", fontFamily: font.mono, letterSpacing: 2 },
  activeLabel: { color: colors.textMuted, fontSize: 13, fontFamily: font.sansRegular },
  cancelBtn: { flexDirection: "row", alignItems: "center", gap: 6, backgroundColor: "rgba(248,113,113,0.14)", borderWidth: 1, borderColor: "rgba(248,113,113,0.32)", borderRadius: 10, paddingHorizontal: 14, paddingVertical: 8, marginTop: 8 },
  cancelLabel: { color: "#FCA5A5", fontWeight: "700", fontSize: 12, fontFamily: font.sansSemibold },
});
