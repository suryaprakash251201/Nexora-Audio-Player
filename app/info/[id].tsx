import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, spacing, accent, shadow, tierColor } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { useDsp } from "@/store/DspContext";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { formatBitDepth, formatBitrate, formatChannels, formatSampleRate } from "@/audio/audioQuality";
import { TechnicalBadge, QualityBadge } from "@/ui/QualityBadge";

function TelemetryRow({ label, value, mono = true }: { label: string; value: string; mono?: boolean }) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Text style={[styles.value, mono && styles.monoValue]} numberOfLines={1}>
        {value}
      </Text>
    </View>
  );
}

export default function InfoScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const decoded = id ? decodeURIComponent(String(id)) : "";
  const lib = useLibrary();
  const dsp = useDsp();
  const insets = useSafeAreaInsets();
  const track = decoded
    ? lib.tracks.find((t) => t.id === decoded) ||
      lib.bySource.nexora.find((t) => t.id === decoded) ||
      lib.bySource.device.find((t) => t.id === decoded) ||
      null
    : null;

  if (!track) {
    return (
      <View style={[styles.root, { alignItems: "center", justifyContent: "center" }]}>
        <Text style={{ color: colors.text, fontFamily: font.sansBold }}>Track not found</Text>
        <Pressable onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>Go Back</Text>
        </Pressable>
      </View>
    );
  }

  const q = track.metadata.quality;
  const isLossless = q?.isLossless ?? (track.metadata.codec ? ["FLAC", "ALAC", "WAV", "AIFF", "DSD"].includes(String(track.metadata.codec).toUpperCase()) : false);

  return (
    <View style={styles.root}>
      <View style={[styles.header, { paddingTop: insets.top + 8 }]}>
        <Pressable
          onPress={() => router.back()}
          style={styles.iconBtn}
          accessibilityLabel="Close"
        >
          <Ionicons name="close" size={18} color={colors.text} />
        </Pressable>
        <View style={{ flex: 1, alignItems: "center" }}>
          <Text style={styles.headerTitle}>STUDIO TELEMETRY</Text>
          <Text numberOfLines={1} style={styles.headerSub}>
            {track.title}
          </Text>
        </View>
        <View style={{ width: 38 }} />
      </View>

      <ScrollView contentContainerStyle={{ padding: spacing.lg, gap: spacing.lg, paddingBottom: insets.bottom + 40 }}>
        {/* Signal Chain Card */}
        <View style={styles.signalCard}>
          <Text style={styles.cardHeader}>LOSSLESS SIGNAL PATH</Text>
          <View style={styles.chainRow}>
            <View style={styles.chainNode}>
              <Ionicons name="server-outline" size={16} color={accent.primary} />
              <Text style={styles.chainText}>Storage</Text>
            </View>
            <Ionicons name="arrow-forward" size={12} color={colors.textMuted} />
            <View style={styles.chainNode}>
              <Ionicons name="hardware-chip-outline" size={16} color={accent.aurora} />
              <Text style={styles.chainText}>Decoder</Text>
            </View>
            <Ionicons name="arrow-forward" size={12} color={colors.textMuted} />
            <View style={styles.chainNode}>
              <Ionicons name="options-outline" size={16} color={dsp.enabled ? "#10B981" : colors.textMuted} />
              <Text style={styles.chainText}>{dsp.enabled ? "DSP 64b" : "Bypass"}</Text>
            </View>
            <Ionicons name="arrow-forward" size={12} color={colors.textMuted} />
            <View style={styles.chainNode}>
              <Ionicons name="headset-outline" size={16} color="#FBBF24" />
              <Text style={styles.chainText}>Output</Text>
            </View>
          </View>
        </View>

        {/* Audio Telemetry Specs */}
        <View style={styles.card}>
          <View style={styles.cardTitleRow}>
            <Text style={styles.cardHeader}>AUDIO STREAM SPECS</Text>
            <QualityBadge track={track} compact />
          </View>
          <TelemetryRow label="Codec" value={String(track.metadata.codec || q?.codec || "PCM")} />
          <TelemetryRow label="Container" value={q?.container || track.metadata.codec || "—"} />
          <TelemetryRow label="Bit Depth" value={formatBitDepth(track.metadata.bitDepth ?? q?.bitDepth ?? null)} />
          <TelemetryRow label="Sample Rate" value={formatSampleRate(track.metadata.sampleRateHz ? track.metadata.sampleRateHz / 1000 : q?.sampleRateKHz ?? null)} />
          <TelemetryRow label="Channels" value={formatChannels(track.metadata.channels ?? q?.channels ?? null)} />
          <TelemetryRow label="Bitrate" value={formatBitrate(track.metadata.bitrateKbps ?? q?.bitrateKbps ?? null)} />
          <TelemetryRow label="Lossless Decoding" value={isLossless ? "VERIFIED BIT-PERFECT" : "LOSSY COMPRESSION"} mono={false} />
          <TelemetryRow label="ReplayGain (Track)" value={track.metadata.replayGainTrackDb != null ? `${track.metadata.replayGainTrackDb.toFixed(1)} dB` : "None"} />
          <TelemetryRow label="ReplayGain (Album)" value={track.metadata.replayGainAlbumDb != null ? `${track.metadata.replayGainAlbumDb.toFixed(1)} dB` : "None"} />
        </View>

        {/* Metadata & Tag Info */}
        <View style={styles.card}>
          <Text style={styles.cardHeader}>TRACK METADATA</Text>
          <TelemetryRow label="Title" value={track.title} mono={false} />
          <TelemetryRow label="Artist" value={track.artist || "Unknown"} mono={false} />
          <TelemetryRow label="Album" value={track.album || "Unknown"} mono={false} />
          <TelemetryRow label="Genre" value={track.genre || "—"} mono={false} />
          <TelemetryRow label="Year" value={track.year ? String(track.year) : "—"} />
          <TelemetryRow label="Track No." value={track.trackNumber ? `${track.trackNumber}${track.discNumber ? ` (disc ${track.discNumber})` : ""}` : "—"} />
          <TelemetryRow label="Audio Source" value={track.source} mono={false} />
        </View>

        {/* File & Storage System */}
        <View style={styles.card}>
          <Text style={styles.cardHeader}>STORAGE & CONTAINER</Text>
          <TelemetryRow label="Server Path" value={track.serverId?.path || track.localUri || "—"} />
          <TelemetryRow label="Mount Root" value={track.serverId?.rootId || "Local Storage"} />
          <TelemetryRow label="File Size" value={track.fileSize ? `${(track.fileSize / (1024 * 1024)).toFixed(2)} MB` : "—"} />
          <TelemetryRow label="Modified" value={track.modifiedAt || "—"} />
          <TelemetryRow label="Cache State" value={track.download.state} />
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.hairlineStrong,
  },
  iconBtn: {
    width: 38,
    height: 38,
    borderRadius: radius.md,
    backgroundColor: "rgba(255,255,255,0.06)",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: colors.hairline,
  },
  headerTitle: {
    color: colors.text,
    fontSize: 13,
    fontWeight: "900",
    fontFamily: font.sansBold,
    letterSpacing: 1.2,
  },
  headerSub: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansMedium,
    marginTop: 2,
  },
  signalCard: {
    backgroundColor: colors.card,
    borderRadius: radius.xl,
    borderWidth: 1,
    borderColor: "rgba(139,92,246,0.3)",
    padding: 16,
    gap: 12,
    ...shadow.glow(accent.primary, 0.15),
  },
  chainRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "rgba(0,0,0,0.35)",
    padding: 12,
    borderRadius: radius.md,
  },
  chainNode: {
    alignItems: "center",
    gap: 4,
  },
  chainText: {
    color: colors.textDim,
    fontSize: 10,
    fontWeight: "800",
    fontFamily: font.sansBold,
  },
  card: {
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    borderRadius: radius.xl,
    padding: 16,
    gap: 8,
    ...shadow.sm,
  },
  cardTitleRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 4,
  },
  cardHeader: {
    color: accent.primary,
    fontWeight: "900",
    fontSize: 11,
    letterSpacing: 1.2,
    fontFamily: font.sansBold,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.04)",
  },
  label: {
    color: colors.textMuted,
    fontSize: 12,
    fontFamily: font.sansMedium,
  },
  value: {
    color: colors.text,
    fontSize: 12,
    fontWeight: "700",
    fontFamily: font.sansSemibold,
    textAlign: "right",
    flex: 1,
    marginLeft: 12,
  },
  monoValue: {
    fontFamily: font.monoBold,
    color: "#E2E8F0",
  },
  backBtn: {
    marginTop: 16,
    backgroundColor: accent.primary,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: radius.md,
  },
  backBtnText: {
    color: "#fff",
    fontWeight: "800",
    fontFamily: font.sansBold,
  },
});