import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Slider } from "@/ui/Slider";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { useDsp, EQ_BAND_LABELS } from "@/store/DspContext";
import { BUILT_IN_PRESETS } from "@/dsp/constants";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Haptics } from "@/lib/haptics";

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View style={s.row}>
      <Text style={s.rowLabel}>{label}</Text>
      <View style={{ flex: 1 }}>{children}</View>
    </View>
  );
}

export default function DspScreen() {
  const dsp = useDsp();
  const insets = useSafeAreaInsets();
  const headroom = dsp.requiredHeadroomDb;
  const needsCut = headroom > Math.abs(dsp.preampDb);

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: insets.top }}>
      <View style={s.header}>
        <Pressable onPress={() => router.back()} style={s.iconBtn}>
          <Ionicons name="close" size={18} color={colors.text} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text style={s.title}>STUDIO DSP</Text>
          <Text style={s.sub}>Preamp · 10-band EQ · Spatial · Limiter — changes are DSP-derived; the source file is never altered.</Text>
        </View>
        <Pressable onPress={() => { Haptics.tapMedium(); dsp.reset(); }} style={[s.iconBtn, { borderColor: "rgba(248,113,113,0.22)" }]}>
          <Ionicons name="refresh" size={16} color="#FCA5A5" />
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: insets.bottom + 16 }}>
        {/* Spatial visual */}
        <View style={s.card}>
          <Text style={s.cardTitle}>Spatial</Text>
          <View style={s.spatialVis}>
            <View style={s.spatialCenter} />
            <View style={[s.spatialDot, { left: 30, top: 36, opacity: 0.7 + dsp.crossfeed * 0.3 }]} />
            <View style={[s.spatialDot, { right: 30, top: 36, opacity: 0.7 + dsp.stereoWidth * 0.15 }]} />
            <Text style={s.spatialHint}>DSP-derived positioning — stereo files have no per-instrument metadata</Text>
          </View>
          <Row label={`Crossfeed ${Math.round(dsp.crossfeed * 100)}%`}>
            <Slider value={dsp.crossfeed} minimumValue={0} maximumValue={1} step={0.01} onValueChange={(v) => dsp.setCrossfeed(v)} minimumTrackTintColor={colors.accent} maximumTrackTintColor="rgba(255,255,255,0.12)" thumbTintColor={colors.accent} />
          </Row>
          <Row label={`Width ${(dsp.stereoWidth).toFixed(2)}×`}>
            <Slider value={dsp.stereoWidth} minimumValue={0.5} maximumValue={1.5} step={0.01} onValueChange={(v) => dsp.setStereoWidth(v)} minimumTrackTintColor={colors.accent} maximumTrackTintColor="rgba(255,255,255,0.12)" thumbTintColor={colors.accent} />
          </Row>
        </View>

        {/* Preamp + headroom */}
        <View style={s.card}>
          <Text style={s.cardTitle}>Gain</Text>
          {needsCut ? (
            <View style={s.warnBox}>
              <Ionicons name="warning-outline" size={14} color="#FBBF24" />
              <Text style={s.warnText}>EQ boosts {headroom} dB — pull preamp down to at least −{headroom} dB or enable limiter to avoid clipping.</Text>
            </View>
          ) : null}
          <Row label={`Preamp ${dsp.preampDb > 0 ? "+" : ""}${dsp.preampDb.toFixed(1)} dB`}>
            <Slider value={dsp.preampDb} minimumValue={-12} maximumValue={12} step={0.5} onValueChange={(v) => dsp.setPreamp(v)} minimumTrackTintColor={colors.accent} maximumTrackTintColor="rgba(255,255,255,0.12)" thumbTintColor={colors.accent} />
          </Row>
          <Row label={`Balance ${dsp.balance > 0 ? "R" : dsp.balance < 0 ? "L" : "C"} ${Math.abs(dsp.balance).toFixed(2)}`}>
            <Slider value={dsp.balance} minimumValue={-1} maximumValue={1} step={0.01} onValueChange={(v) => dsp.setBalance(v)} minimumTrackTintColor={colors.accent} maximumTrackTintColor="rgba(255,255,255,0.12)" thumbTintColor={colors.accent} />
          </Row>
          <Row label="Limiter">
            <Pressable onPress={() => { Haptics.tapLight(); dsp.setLimiterEnabled(!dsp.limiterEnabled); }} style={[s.toggle, dsp.limiterEnabled && s.toggleOn]}>
              <Text style={[s.toggleLabel, dsp.limiterEnabled && s.toggleLabelOn]}>{dsp.limiterEnabled ? "ON" : "OFF"}</Text>
            </Pressable>
          </Row>
          <Row label={`ReplayGain · ${dsp.replayGainMode}`}>
            <View style={{ flexDirection: "row", gap: 8 }}>
              {(["off", "track", "album"] as const).map((m) => (
                <Pressable key={m} onPress={() => { Haptics.selection(); dsp.setReplayGainMode(m); }} style={[s.chip, dsp.replayGainMode === m && s.chipOn]}>
                  <Text style={[s.chipLabel, dsp.replayGainMode === m && s.chipLabelOn]}>{m}</Text>
                </Pressable>
              ))}
            </View>
          </Row>
        </View>

        {/* 10-band EQ */}
        <View style={s.card}>
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
            <Text style={s.cardTitle}>10-band EQ</Text>
            <Pressable onPress={() => { Haptics.tapLight(); dsp.setEnabled(!dsp.enabled); }} style={[s.toggle, dsp.enabled && s.toggleOn]}>
              <Text style={[s.toggleLabel, dsp.enabled && s.toggleLabelOn]}>{dsp.enabled ? "ON" : "OFF"}</Text>
            </Pressable>
          </View>
          <Text style={s.eqHint}>31 Hz → 16 kHz · −12 dB … +12 dB · Native EQ (AudioUnitEQ / android.media.audiofx) when available, JS biquad fallback otherwise.</Text>

          <View style={s.eqGrid}>
            {dsp.gainsDb.map((gain, i) => (
              <View key={i} style={s.eqBand}>
                <Text style={[s.eqGain, gain > 0 && { color: "#22C55E" }, gain < 0 && { color: "#38BDF8" }]}>{gain > 0 ? `+${gain.toFixed(0)}` : `${gain.toFixed(0)}`}</Text>
                <View style={s.sliderVWrap}>
                  <Slider
                    value={gain}
                    minimumValue={-12}
                    maximumValue={12}
                    step={0.5}
                    onValueChange={(v) => dsp.setGainAt(i, v)}
                    minimumTrackTintColor={colors.accent}
                    maximumTrackTintColor="rgba(255,255,255,0.12)"
                    thumbTintColor={colors.accent}
                    style={{ height: 120 }}
                    // vertical: true not supported on all RN slider versions — keep horizontal and rotate
                  />
                </View>
                <Text style={s.eqLabel}>{EQ_BAND_LABELS[i]}</Text>
                <Text style={s.eqHz}>{[31,62,125,250,500,1000,2000,4000,8000,16000][i]} Hz</Text>
              </View>
            ))}
          </View>
          <View style={{ flexDirection: "row", gap: 8, flexWrap: "wrap" }}>
            {BUILT_IN_PRESETS.map((p) => (
              <Pressable key={p.id} onPress={() => { Haptics.selection(); dsp.applyPreset(p.id); }} style={[s.chip, dsp.presetId === p.id && s.chipOn]}>
                <Text style={[s.chipLabel, dsp.presetId === p.id && s.chipLabelOn]}>{p.name}</Text>
              </Pressable>
            ))}
          </View>
          <Text style={s.eqFoot}>Analyzer (FFT / waveform / spectrogram) lives on the Now Playing waveform — tap it to expand. Live meters use the same DSP-derived PCM; values labeled “estimated” when not calibrated.</Text>
        </View>
      </ScrollView>
    </View>
  );
}

const s = StyleSheet.create({
  header: { flexDirection: "row", gap: 10, alignItems: "center", paddingHorizontal: 16, paddingBottom: 10 },
  iconBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  title: { color: colors.text, fontSize: 14, fontWeight: "900", letterSpacing: 1.2 },
  sub: { color: colors.textMuted, fontSize: 11, lineHeight: 13, marginTop: 2 },
  card: { backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 14, padding: 14, gap: 12 },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 13, letterSpacing: 0.4 },
  spatialVis: { height: 90, borderRadius: 12, backgroundColor: "rgba(139,92,246,0.08)", borderWidth: 1, borderColor: "rgba(139,92,246,0.18)", alignItems: "center", justifyContent: "center" },
  spatialCenter: { width: 10, height: 10, borderRadius: 5, backgroundColor: colors.accent },
  spatialDot: { position: "absolute", width: 14, height: 14, borderRadius: 7, backgroundColor: "#38BDF8", borderWidth: 2, borderColor: "#fff" },
  spatialHint: { position: "absolute", bottom: 8, color: colors.textMuted, fontSize: 9, textAlign: "center", paddingHorizontal: 12 },
  row: { flexDirection: "row", alignItems: "center", gap: 10 },
  rowLabel: { width: 132, color: colors.textDim, fontSize: 12, fontWeight: "600" },
  warnBox: { flexDirection: "row", gap: 8, alignItems: "flex-start", backgroundColor: "rgba(251,191,36,0.12)", borderWidth: 1, borderColor: "rgba(251,191,36,0.22)", borderRadius: 10, padding: 10 },
  warnText: { flex: 1, color: "#FDE68A", fontSize: 11, lineHeight: 14 },
  toggle: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, paddingHorizontal: 12, height: 28, borderRadius: 8, alignItems: "center", justifyContent: "center" },
  toggleOn: { backgroundColor: colors.accent, borderColor: colors.accent },
  toggleLabel: { color: colors.textMuted, fontWeight: "800", fontSize: 11 },
  toggleLabelOn: { color: "#fff" },
  chip: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, paddingHorizontal: 10, height: 28, borderRadius: 8, alignItems: "center", justifyContent: "center" },
  chipOn: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipLabel: { color: colors.textMuted, fontWeight: "700", fontSize: 11, textTransform: "capitalize" },
  chipLabelOn: { color: "#fff" },
  eqHint: { color: colors.textMuted, fontSize: 11, lineHeight: 14 },
  eqGrid: { flexDirection: "row", gap: 6, justifyContent: "space-between" },
  eqBand: { flex: 1, alignItems: "center", gap: 4 },
  eqGain: { color: colors.textMuted, fontSize: 10, fontWeight: "700", fontVariant: ["tabular-nums"] as any },
  sliderVWrap: { height: 120, width: 28, alignItems: "center", justifyContent: "center" },
  eqLabel: { color: colors.textDim, fontSize: 10, fontWeight: "700" },
  eqHz: { color: colors.textMuted, fontSize: 9 },
  eqFoot: { color: colors.textMuted, fontSize: 11, lineHeight: 14 },
});