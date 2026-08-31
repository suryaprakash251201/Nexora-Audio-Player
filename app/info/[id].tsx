import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { useLibrary } from "@/store/LibraryContext";
import { useDsp } from "@/store/DspContext";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { formatBitDepth, formatBitrate, formatChannels, formatSampleRate } from "@/audio/audioQuality";

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={s.row}>
      <Text style={s.label}>{label}</Text>
      <Text style={s.value}>{value}</Text>
    </View>
  );
}

export default function InfoScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const decoded = id ? decodeURIComponent(String(id)) : "";
  const lib = useLibrary();
  const dsp = useDsp();
  const insets = useSafeAreaInsets();
  const track = decoded ? lib.tracks.find((t) => t.id === decoded) || lib.bySource.nexora.find((t) => t.id === decoded) || lib.bySource.device.find((t) => t.id === decoded) || null : null;

  if (!track) {
    return (
      <View style={[s.root, { alignItems: "center", justifyContent: "center" }]}>
        <Text style={{ color: colors.text }}>Track not found</Text>
        <Pressable onPress={() => router.back()} style={s.btn}><Text style={s.btnLabel}>Back</Text></Pressable>
      </View>
    );
  }

  const q = track.metadata.quality;
  const dspNote = dsp.enabled ? "DSP ON — output is processed (headroom applied)" : "DSP OFF — source preserved where the platform supports it";

  return (
    <View style={s.root}>
      <View style={[s.header, { paddingTop: insets.top + 10 }]}>
        <Pressable onPress={() => router.back()} style={s.iconBtn}>
          <Ionicons name="close" size={18} color={colors.text} />
        </Pressable>
        <Text style={s.title}>Info</Text>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 14 }}>
        <View style={s.card}>
          <Text style={s.cardTitle}>Track Info</Text>
          <Row label="Title" value={track.title} />
          <Row label="Artist" value={track.artist || "—"} />
          <Row label="Album" value={track.album || "—"} />
          <Row label="Album artist" value={track.albumArtist || "—"} />
          <Row label="Genre" value={track.genre || "—"} />
          <Row label="Year" value={track.year ? String(track.year) : "—"} />
          <Row label="Track" value={track.trackNumber ? `${track.trackNumber}${track.discNumber ? ` (disc ${track.discNumber})` : ""}` : "—"} />
          <Row label="Source" value={track.source} />
        </View>

        <View style={s.card}>
          <Text style={s.cardTitle}>Audio Info</Text>
          <Row label="Codec" value={String(track.metadata.codec || q?.codec || "—")} />
          <Row label="Format" value={q?.container || "—"} />
          <Row label="Bit depth" value={formatBitDepth(track.metadata.bitDepth ?? q?.bitDepth ?? null)} />
          <Row label="Sample rate" value={formatSampleRate(track.metadata.sampleRateHz ? track.metadata.sampleRateHz / 1000 : q?.sampleRateKHz ?? null)} />
          <Row label="Channels" value={formatChannels(track.metadata.channels ?? q?.channels ?? null)} />
          <Row label="Bitrate" value={formatBitrate(track.metadata.bitrateKbps ?? q?.bitrateKbps ?? null)} />
          <Row label="Duration" value={track.metadata.durationSec ? `${Math.floor(track.metadata.durationSec / 60)}:${String(Math.floor(track.metadata.durationSec % 60)).padStart(2, "0")}` : "—"} />
          <Row label="Lossless" value={q?.isLossless ? "Yes" : q ? "No" : "unknown"} />
          <Row label="ReplayGain (track)" value={track.metadata.replayGainTrackDb != null ? `${track.metadata.replayGainTrackDb.toFixed(1)} dB` : "—"} />
          <Row label="ReplayGain (album)" value={track.metadata.replayGainAlbumDb != null ? `${track.metadata.replayGainAlbumDb.toFixed(1)} dB` : "—"} />
          <Text style={s.hint}>{dspNote} · 24BIT | 192 kHz | FLAC badge shows the detected quality, not a marketing claim.</Text>
        </View>

        <View style={s.card}>
          <Text style={s.cardTitle}>File Info</Text>
          <Row label="Path" value={track.serverId?.path || track.localUri || "—"} />
          <Row label="Root" value={track.serverId?.rootId || "—"} />
          <Row label="Size" value={track.fileSize ? `${(track.fileSize / (1024 * 1024)).toFixed(1)} MB` : "—"} />
          <Row label="Modified" value={track.modifiedAt || "—"} />
          <Row label="Download" value={track.download.state} />
          {Object.keys(track.metadata.tags).length ? (
            <>
              <Text style={[s.cardTitle, { marginTop: 8 }]}>Tags</Text>
              {Object.entries(track.metadata.tags).slice(0, 20).map(([k, v]) => (
                <Row key={k} label={k} value={String(v).slice(0, 80)} />
              ))}
            </>
          ) : null}
        </View>
      </ScrollView>
    </View>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 12, paddingTop: 12, paddingBottom: 8 },
  iconBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  title: { color: colors.text, fontSize: 16, fontWeight: "800" },
  card: { backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 14, padding: 14, gap: 8 },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 12, letterSpacing: 0.5, textTransform: "uppercase" },
  row: { flexDirection: "row", justifyContent: "space-between", gap: 12, paddingVertical: 4, borderBottomWidth: 1, borderBottomColor: "rgba(255,255,255,0.04)" },
  label: { color: colors.textMuted, fontSize: 12, flex: 1 },
  value: { color: colors.text, fontSize: 12, fontWeight: "600", flex: 1.2, textAlign: "right" },
  hint: { color: colors.textMuted, fontSize: 11, lineHeight: 14, marginTop: 6 },
  btn: { backgroundColor: colors.accent, paddingHorizontal: 16, paddingVertical: 10, borderRadius: 10, marginTop: 12 },
  btnLabel: { color: "#fff", fontWeight: "800" },
});