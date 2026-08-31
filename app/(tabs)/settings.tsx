import React from "react";
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, radius, spacing, tierColor } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { useDsp } from "@/store/DspContext";
import { useLibrary } from "@/store/LibraryContext";
import { useDownloads } from "@/store/DownloadsContext";
import { PageHeader } from "@/ui/PageHeader";
import { Container } from "@/ui/Container";
import { Haptics } from "@/lib/haptics";
import { Toast } from "@/ui/Toast";

export default function SettingsScreen() {
  const { api, user, baseUrl, logout } = useSession();
  const dsp = useDsp();
  const lib = useLibrary();
  const downloads = useDownloads();
  const insets = useSafeAreaInsets();

  const onLogout = () => {
    Haptics.tapMedium();
    Alert.alert("Sign out?", "You will be asked to connect again.", [
      { text: "Cancel", style: "cancel" },
      { text: "Sign out", style: "destructive", onPress: () => { void logout().then(() => Toast.success("Signed out")); } },
    ]);
  };

  return (
    <Container padded={false}>
      <PageHeader
        kicker="Account"
        title="Settings"
        subtitle={api ? `Signed in as ${user?.username ?? "user"}` : "Not connected"}
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: spacing.lg, paddingBottom: insets.bottom + 40, gap: spacing.md }}>
        {/* Server card */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <View style={[styles.iconBox, { backgroundColor: "rgba(96,165,250,0.16)" }]}>
              <Ionicons name="cloud-outline" size={20} color="#60A5FA" />
            </View>
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={styles.cardTitle}>Server</Text>
              <Text style={styles.cardSubtitle} numberOfLines={1}>{baseUrl ?? "Not connected"}</Text>
              <Text style={styles.cardHint}>{user ? `${user.username} · ${user.role}` : "Not signed in"}</Text>
            </View>
          </View>
          <View style={{ flexDirection: "row", gap: 8, marginTop: 4 }}>
            <Pressable onPress={() => router.push("/login")} style={[styles.btn, { flex: 1 }]}>
              <Ionicons name="swap-horizontal" size={14} color="#fff" />
              <Text style={styles.btnLabel}>{api ? "Change server" : "Connect"}</Text>
            </Pressable>
            {api ? (
              <Pressable onPress={onLogout} style={[styles.btn, { backgroundColor: "rgba(248,113,113,0.16)", borderWidth: 1, borderColor: "rgba(248,113,113,0.32)" }]}>
                <Ionicons name="log-out-outline" size={14} color="#FCA5A5" />
                <Text style={[styles.btnLabel, { color: "#FCA5A5" }]}>Sign out</Text>
              </Pressable>
            ) : null}
          </View>
        </View>

        {/* Library status */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <View style={[styles.iconBox, { backgroundColor: "rgba(34,197,94,0.16)" }]}>
              <Ionicons name="library-outline" size={20} color="#22C55E" />
            </View>
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={styles.cardTitle}>Library</Text>
              <Text style={styles.cardSubtitle}>{lib.counts.unified.toLocaleString()} tracks · {downloads.totalOffline} downloaded</Text>
              <Text style={styles.cardHint}>Nexora {lib.counts.nexora} · Device {lib.counts.device} · Offline {lib.counts.offline}</Text>
            </View>
          </View>
        </View>

        {/* DSP */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <View style={[styles.iconBox, { backgroundColor: dsp.enabled ? "rgba(139,92,246,0.18)" : "rgba(255,255,255,0.06)" }]}>
              <Ionicons name="options-outline" size={20} color={dsp.enabled ? colors.accent : colors.textDim} />
            </View>
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={styles.cardTitle}>Studio DSP</Text>
              <Text style={styles.cardSubtitle}>{dsp.enabled ? "10-band EQ + Preamp" : "Off (source preserved)"}</Text>
              <Text style={styles.cardHint}>Limiter {dsp.limiterEnabled ? "ON" : "OFF"} · ReplayGain {dsp.replayGainMode}</Text>
            </View>
          </View>
          <View style={{ flexDirection: "row", gap: 8, marginTop: 6 }}>
            <Pressable onPress={() => router.push("/dsp" as any)} style={[styles.btn, { flex: 1 }]}>
              <Ionicons name="options" size={14} color="#fff" />
              <Text style={styles.btnLabel}>Open DSP</Text>
            </Pressable>
            <Pressable onPress={() => { dsp.setEnabled(!dsp.enabled); Haptics.tapMedium(); Toast.info(`DSP ${!dsp.enabled ? "on" : "off"}`); }} style={[styles.btn, { backgroundColor: dsp.enabled ? "rgba(34,197,94,0.16)" : "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: dsp.enabled ? "rgba(34,197,94,0.32)" : colors.hairline }]}>
              <Ionicons name={dsp.enabled ? "checkmark" : "power"} size={14} color={dsp.enabled ? "#22C55E" : colors.text} />
              <Text style={[styles.btnLabel, { color: dsp.enabled ? "#22C55E" : colors.text }]}>{dsp.enabled ? "Enabled" : "Enable"}</Text>
            </Pressable>
          </View>
        </View>

        {/* Quality tier legend */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Quality tiers</Text>
          <Text style={styles.cardSubtitle}>What your audio metadata can show</Text>
          <View style={{ marginTop: 8, gap: 6 }}>
            {(["mp3", "aac", "lossless", "hires", "dsd", "dolby", "spatial"] as const).map((k) => (
              <View key={k} style={styles.legendRow}>
                <View style={[styles.legendChip, { backgroundColor: tierColor[k].soft }]}>
                  <Text style={[styles.legendLabel, { color: tierColor[k].accent }]}>{tierColor[k].label}</Text>
                </View>
                <Text style={styles.legendHint}>
                  {k === "mp3" ? "Standard lossy · ≤320 kbps" :
                   k === "aac" ? "High quality lossy · 256 kbps default" :
                   k === "lossless" ? "CD-quality · 16-bit / 44.1 kHz" :
                   k === "hires" ? "Hi-res · 24-bit · ≥88.2 kHz" :
                   k === "dsd" ? "DSD · Direct Stream Digital" :
                   k === "dolby" ? "Dolby Atmos · spatial" :
                   "Spatial audio (DSP-derived)"}
                </Text>
              </View>
            ))}
          </View>
        </View>

        <Text style={styles.footer}>Nexora Audiophile · M19 visual system · 24BIT | 192kHz | FLAC{'\n'}Build with Expo 54, RN 0.81, TrackPlayer 4.1.2.</Text>
      </ScrollView>
    </Container>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.card, borderWidth: 1, borderColor: colors.hairline, borderRadius: radius.lg, padding: 16, gap: 4 },
  cardHeader: { flexDirection: "row", alignItems: "flex-start", gap: 12 },
  iconBox: { width: 44, height: 44, borderRadius: 12, alignItems: "center", justifyContent: "center" },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 14, fontFamily: font.sansBold },
  cardSubtitle: { color: colors.textDim, fontSize: 12, fontFamily: font.sansMedium, fontWeight: "600" },
  cardHint: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular },
  btn: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 6, backgroundColor: colors.accent, paddingVertical: 10, paddingHorizontal: 14, borderRadius: 12 },
  btnLabel: { color: "#fff", fontWeight: "800", fontSize: 12, fontFamily: font.sansBold },
  legendRow: { flexDirection: "row", alignItems: "center", gap: 10 },
  legendChip: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 6, minWidth: 86, alignItems: "center" },
  legendLabel: { fontSize: 9, fontWeight: "800", letterSpacing: 0.6, fontFamily: font.sansBold },
  legendHint: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular, flex: 1 },
  footer: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular, textAlign: "center", marginTop: spacing.md, lineHeight: 16 },
});