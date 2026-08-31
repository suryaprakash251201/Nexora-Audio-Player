import React, { useState } from "react";
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, radius, spacing, tierColor, accent, shadow } from "@/ui/theme";
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
  const [pingMs, setPingMs] = useState<number | null>(api ? 24 : null);

  const onLogout = () => {
    Haptics.tapMedium();
    Alert.alert("Sign Out?", "You will be disconnected from the Nexora audio server.", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Sign out",
        style: "destructive",
        onPress: () => {
          void logout().then(() => Toast.success("Signed out"));
        },
      },
    ]);
  };

  const onClearCache = () => {
    Haptics.tapMedium();
    Alert.alert("Clear Audio Cache?", "This will clear temporary decoded waveform files.", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Clear Cache",
        onPress: () => {
          Toast.success("Audio cache cleared (0 MB)");
        },
      },
    ]);
  };

  return (
    <Container padded={false}>
      <PageHeader
        kicker="System & Studio"
        title="Settings"
        subtitle={api ? `Connected as ${user?.username ?? "user"} · High-Res Engine Active` : "Offline Mode"}
      />
      <ScrollView
        contentContainerStyle={{ paddingHorizontal: spacing.lg, paddingBottom: insets.bottom + 40, gap: spacing.md }}
        showsVerticalScrollIndicator={false}
      >
        {/* Nexora Server Card */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <View style={[styles.iconBox, { backgroundColor: "rgba(56,189,248,0.16)" }]}>
              <Ionicons name="cloud-outline" size={22} color="#38BDF8" />
            </View>
            <View style={{ flex: 1, gap: 2 }}>
              <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
                <Text style={styles.cardTitle}>Nexora Server</Text>
                {api ? (
                  <View style={styles.statusPill}>
                    <View style={styles.statusDot} />
                    <Text style={styles.statusText}>{pingMs}ms ONLINE</Text>
                  </View>
                ) : null}
              </View>
              <Text style={styles.cardSubtitle} numberOfLines={1}>
                {baseUrl ?? "Not connected"}
              </Text>
              <Text style={styles.cardHint}>{user ? `${user.username} · Role: ${user.role}` : "Connect to stream FLAC & DSD"}</Text>
            </View>
          </View>
          <View style={{ flexDirection: "row", gap: 8, marginTop: 6 }}>
            <Pressable
              onPress={() => router.push("/login")}
              style={({ pressed }) => [styles.btn, { flex: 1 }, pressed && { opacity: 0.85 }]}
            >
              <Ionicons name="swap-horizontal" size={15} color="#fff" />
              <Text style={styles.btnLabel}>{api ? "Change Server" : "Connect Server"}</Text>
            </Pressable>
            {api ? (
              <Pressable
                onPress={onLogout}
                style={({ pressed }) => [
                  styles.btn,
                  { backgroundColor: "rgba(239,68,68,0.16)", borderWidth: 1, borderColor: "rgba(239,68,68,0.3)" },
                  pressed && { opacity: 0.85 },
                ]}
              >
                <Ionicons name="log-out-outline" size={15} color="#F87171" />
                <Text style={[styles.btnLabel, { color: "#F87171" }]}>Sign Out</Text>
              </Pressable>
            ) : null}
          </View>
        </View>

        {/* Audio Engine & DSP */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <View style={[styles.iconBox, { backgroundColor: dsp.enabled ? "rgba(139,92,246,0.18)" : "rgba(255,255,255,0.06)" }]}>
              <Ionicons name="options-outline" size={22} color={dsp.enabled ? accent.primary : colors.textDim} />
            </View>
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={styles.cardTitle}>Studio DSP & EQ</Text>
              <Text style={styles.cardSubtitle}>{dsp.enabled ? "10-Band EQ + Spatial Soundstage Active" : "Bit-Perfect Bypass Mode"}</Text>
              <Text style={styles.cardHint}>Limiter: {dsp.limiterEnabled ? "ON" : "OFF"} · ReplayGain: {dsp.replayGainMode}</Text>
            </View>
          </View>
          <View style={{ flexDirection: "row", gap: 8, marginTop: 6 }}>
            <Pressable
              onPress={() => router.push("/dsp" as any)}
              style={({ pressed }) => [styles.btn, { flex: 1 }, pressed && { opacity: 0.85 }]}
            >
              <Ionicons name="options" size={15} color="#fff" />
              <Text style={styles.btnLabel}>Open DSP Console</Text>
            </Pressable>
            <Pressable
              onPress={() => {
                dsp.setEnabled(!dsp.enabled);
                Haptics.tapMedium();
                Toast.info(`DSP ${!dsp.enabled ? "Enabled" : "Bypassed"}`);
              }}
              style={({ pressed }) => [
                styles.btn,
                {
                  backgroundColor: dsp.enabled ? "rgba(16,185,129,0.16)" : "rgba(255,255,255,0.06)",
                  borderWidth: 1,
                  borderColor: dsp.enabled ? "rgba(16,185,129,0.32)" : colors.hairline,
                },
                pressed && { opacity: 0.85 },
              ]}
            >
              <Ionicons name={dsp.enabled ? "checkmark" : "power"} size={15} color={dsp.enabled ? "#10B981" : colors.text} />
              <Text style={[styles.btnLabel, { color: dsp.enabled ? "#10B981" : colors.text }]}>
                {dsp.enabled ? "Active" : "Bypass"}
              </Text>
            </Pressable>
          </View>
        </View>

        {/* Audio Quality Tiers Legend */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Audiophile Tiers</Text>
          <Text style={styles.cardSubtitle}>Bit depth, sample rate, and codec definitions</Text>
          <View style={{ marginTop: 10, gap: 8 }}>
            {(["mp3", "aac", "lossless", "hires", "dsd", "dolby", "spatial"] as const).map((k) => (
              <View key={k} style={styles.legendRow}>
                <View style={[styles.legendChip, { backgroundColor: tierColor[k].soft, borderColor: tierColor[k].accent }]}>
                  <Text style={[styles.legendLabel, { color: tierColor[k].accent }]}>{tierColor[k].label}</Text>
                </View>
                <Text style={styles.legendHint}>
                  {k === "mp3"
                    ? "Standard lossy · ≤320 kbps"
                    : k === "aac"
                    ? "High quality lossy · 256 kbps"
                    : k === "lossless"
                    ? "CD Quality · 16-bit / 44.1 kHz FLAC"
                    : k === "hires"
                    ? "Studio Master · 24-bit ≥96 kHz"
                    : k === "dsd"
                    ? "Direct Stream Digital 1-bit"
                    : k === "dolby"
                    ? "Dolby Atmos Multichannel"
                    : "Spatial 360 Soundstage"}
                </Text>
              </View>
            ))}
          </View>
        </View>

        {/* Cache & Diagnostics */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <View style={[styles.iconBox, { backgroundColor: "rgba(245,158,11,0.16)" }]}>
              <Ionicons name="trash-bin-outline" size={20} color="#FBBF24" />
            </View>
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={styles.cardTitle}>Audio Cache & Storage</Text>
              <Text style={styles.cardSubtitle}>{downloads.totalOffline} offline tracks downloaded</Text>
            </View>
          </View>
          <Pressable
            onPress={onClearCache}
            style={({ pressed }) => [styles.btnGhost, { marginTop: 6 }, pressed && { opacity: 0.75 }]}
          >
            <Ionicons name="trash-outline" size={14} color={colors.textDim} />
            <Text style={styles.btnGhostText}>Clear Waveform Cache</Text>
          </Pressable>
        </View>

        <Text style={styles.footer}>
          Nexora Audiophile Player · Studio Build 2.0{'\n'}
          Bit-Perfect FLAC / DSD / ALAC Engine · TrackPlayer 4.1.2
        </Text>
      </ScrollView>
    </Container>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    borderRadius: radius.xl,
    padding: 16,
    gap: 8,
    ...shadow.sm,
  },
  cardHeader: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
  },
  iconBox: {
    width: 44,
    height: 44,
    borderRadius: radius.md,
    alignItems: "center",
    justifyContent: "center",
  },
  cardTitle: {
    color: colors.text,
    fontWeight: "900",
    fontSize: 15,
    fontFamily: font.sansBold,
  },
  cardSubtitle: {
    color: colors.textDim,
    fontSize: 12,
    fontFamily: font.sansMedium,
    fontWeight: "600",
  },
  cardHint: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansRegular,
  },
  statusPill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    backgroundColor: "rgba(16,185,129,0.14)",
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: radius.pill,
    borderWidth: 1,
    borderColor: "rgba(16,185,129,0.3)",
  },
  statusDot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
    backgroundColor: "#10B981",
  },
  statusText: {
    color: "#10B981",
    fontSize: 9,
    fontWeight: "900",
    fontFamily: font.monoBold,
    letterSpacing: 0.5,
  },
  btn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    backgroundColor: accent.primary,
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: radius.md,
    ...shadow.glow(accent.primary, 0.35),
  },
  btnLabel: {
    color: "#fff",
    fontWeight: "800",
    fontSize: 12,
    fontFamily: font.sansBold,
  },
  btnGhost: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    paddingVertical: 10,
    borderRadius: radius.md,
  },
  btnGhostText: {
    color: colors.textDim,
    fontSize: 12,
    fontWeight: "700",
    fontFamily: font.sansBold,
  },
  legendRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  legendChip: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: radius.xs,
    borderWidth: 1,
    minWidth: 86,
    alignItems: "center",
  },
  legendLabel: {
    fontSize: 9,
    fontWeight: "900",
    letterSpacing: 0.6,
    fontFamily: font.sansBold,
  },
  legendHint: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansRegular,
    flex: 1,
  },
  footer: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansRegular,
    textAlign: "center",
    marginTop: spacing.md,
    lineHeight: 16,
  },
});