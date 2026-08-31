import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Slider } from "@/ui/Slider";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, spacing, accent, shadow } from "@/ui/theme";
import { useDsp, EQ_BAND_LABELS } from "@/store/DspContext";
import { BUILT_IN_PRESETS } from "@/dsp/constants";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Haptics } from "@/lib/haptics";

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
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
      {/* Studio Header */}
      <View style={styles.header}>
        <Pressable
          onPress={() => router.back()}
          style={styles.iconBtn}
          accessibilityLabel="Close"
        >
          <Ionicons name="close" size={18} color={colors.text} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <View style={styles.kickerRow}>
            <View style={styles.kickerDot} />
            <Text style={styles.kicker}>STUDIO CONSOLE</Text>
          </View>
          <Text style={styles.title}>Parametric DSP Engine</Text>
        </View>
        <Pressable
          onPress={() => {
            Haptics.tapMedium();
            dsp.reset();
          }}
          style={[styles.iconBtn, { borderColor: "rgba(239,68,68,0.3)" }]}
          accessibilityLabel="Reset DSP"
        >
          <Ionicons name="refresh" size={16} color="#F87171" />
        </Pressable>
      </View>

      <ScrollView
        contentContainerStyle={{ padding: spacing.lg, gap: spacing.lg, paddingBottom: insets.bottom + 40 }}
        showsVerticalScrollIndicator={false}
      >
        {/* 360 Spatial Soundstage */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Ionicons name="radio-outline" size={16} color={accent.aurora} />
            <Text style={styles.cardTitle}>Spatial Soundstage</Text>
          </View>

          <View style={styles.spatialVis}>
            {/* Concentric sound wave rings */}
            <View style={[styles.soundRing, { width: 140, height: 140, borderRadius: 70 }]} />
            <View style={[styles.soundRing, { width: 90, height: 90, borderRadius: 45 }]} />
            <View style={styles.spatialCenter}>
              <Ionicons name="headset" size={16} color="#fff" />
            </View>
            {/* Left/Right channel satellites */}
            <View style={[styles.spatialDot, { left: 40, top: 40, opacity: 0.7 + dsp.crossfeed * 0.3 }]}>
              <Text style={styles.channelLabel}>L</Text>
            </View>
            <View style={[styles.spatialDot, { right: 40, top: 40, opacity: 0.7 + dsp.stereoWidth * 0.15 }]}>
              <Text style={styles.channelLabel}>R</Text>
            </View>
            <Text style={styles.spatialHint}>Real-time binaural crossfeed & soundstage widening</Text>
          </View>

          <Row label={`Crossfeed: ${Math.round(dsp.crossfeed * 100)}%`}>
            <Slider
              value={dsp.crossfeed}
              minimumValue={0}
              maximumValue={1}
              step={0.01}
              onValueChange={(v) => dsp.setCrossfeed(v)}
              minimumTrackTintColor={accent.aurora}
              maximumTrackTintColor="rgba(255,255,255,0.12)"
              thumbTintColor={accent.aurora}
            />
          </Row>
          <Row label={`Width: ${(dsp.stereoWidth).toFixed(2)}×`}>
            <Slider
              value={dsp.stereoWidth}
              minimumValue={0.5}
              maximumValue={1.5}
              step={0.01}
              onValueChange={(v) => dsp.setStereoWidth(v)}
              minimumTrackTintColor={accent.aurora}
              maximumTrackTintColor="rgba(255,255,255,0.12)"
              thumbTintColor={accent.aurora}
            />
          </Row>
        </View>

        {/* Studio Gain & Limiter */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Ionicons name="pulse-outline" size={16} color="#FBBF24" />
            <Text style={styles.cardTitle}>Gain & Dynamics</Text>
          </View>

          {needsCut ? (
            <View style={styles.warnBox}>
              <Ionicons name="warning-outline" size={16} color="#FBBF24" />
              <Text style={styles.warnText}>
                EQ boosts +{headroom} dB. Pull preamp down or enable Limiter to avoid clipping distortion.
              </Text>
            </View>
          ) : null}

          <Row label={`Preamp: ${dsp.preampDb > 0 ? "+" : ""}${dsp.preampDb.toFixed(1)} dB`}>
            <Slider
              value={dsp.preampDb}
              minimumValue={-12}
              maximumValue={12}
              step={0.5}
              onValueChange={(v) => dsp.setPreamp(v)}
              minimumTrackTintColor={accent.primary}
              maximumTrackTintColor="rgba(255,255,255,0.12)"
              thumbTintColor={accent.primary}
            />
          </Row>
          <Row label={`Balance: ${dsp.balance > 0 ? "R" : dsp.balance < 0 ? "L" : "C"} ${Math.abs(dsp.balance).toFixed(2)}`}>
            <Slider
              value={dsp.balance}
              minimumValue={-1}
              maximumValue={1}
              step={0.01}
              onValueChange={(v) => dsp.setBalance(v)}
              minimumTrackTintColor={accent.primary}
              maximumTrackTintColor="rgba(255,255,255,0.12)"
              thumbTintColor={accent.primary}
            />
          </Row>
          <Row label="Brickwall Limiter">
            <Pressable
              onPress={() => {
                Haptics.tapLight();
                dsp.setLimiterEnabled(!dsp.limiterEnabled);
              }}
              style={[styles.toggle, dsp.limiterEnabled && styles.toggleOn]}
            >
              <Text style={[styles.toggleLabel, dsp.limiterEnabled && styles.toggleLabelOn]}>
                {dsp.limiterEnabled ? "ACTIVE" : "BYPASS"}
              </Text>
            </Pressable>
          </Row>
          <Row label={`ReplayGain · ${dsp.replayGainMode}`}>
            <View style={{ flexDirection: "row", gap: 6 }}>
              {(["off", "track", "album"] as const).map((m) => (
                <Pressable
                  key={m}
                  onPress={() => {
                    Haptics.selection();
                    dsp.setReplayGainMode(m);
                  }}
                  style={[styles.chip, dsp.replayGainMode === m && styles.chipOn]}
                >
                  <Text style={[styles.chipLabel, dsp.replayGainMode === m && styles.chipLabelOn]}>{m}</Text>
                </Pressable>
              ))}
            </View>
          </Row>
        </View>

        {/* 10-Band Parametric Equalizer */}
        <View style={styles.card}>
          <View style={styles.cardHeaderBetween}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
              <Ionicons name="stats-chart" size={16} color={accent.primary} />
              <Text style={styles.cardTitle}>10-Band Studio Equalizer</Text>
            </View>
            <Pressable
              onPress={() => {
                Haptics.tapLight();
                dsp.setEnabled(!dsp.enabled);
              }}
              style={[styles.toggle, dsp.enabled && styles.toggleOn]}
            >
              <Text style={[styles.toggleLabel, dsp.enabled && styles.toggleLabelOn]}>
                {dsp.enabled ? "ACTIVE" : "BYPASS"}
              </Text>
            </Pressable>
          </View>
          <Text style={styles.eqHint}>
            31 Hz → 16 kHz · −12 dB … +12 dB · Bit-accurate biquad processing
          </Text>

          <View style={styles.eqGrid}>
            {dsp.gainsDb.map((gain, i) => (
              <View key={i} style={styles.eqBand}>
                <Text style={[styles.eqGain, gain > 0 && { color: "#10B981" }, gain < 0 && { color: "#38BDF8" }]}>
                  {gain > 0 ? `+${gain.toFixed(0)}` : `${gain.toFixed(0)}`}
                </Text>
                <View style={styles.sliderVWrap}>
                  <Slider
                    value={gain}
                    minimumValue={-12}
                    maximumValue={12}
                    step={0.5}
                    onValueChange={(v) => dsp.setGainAt(i, v)}
                    minimumTrackTintColor={accent.primary}
                    maximumTrackTintColor="rgba(255,255,255,0.12)"
                    thumbTintColor={accent.primary}
                    style={{ height: 120 }}
                  />
                </View>
                <Text style={styles.eqLabel}>{EQ_BAND_LABELS[i]}</Text>
                <Text style={styles.eqHz}>{[31, 62, 125, 250, 500, "1k", "2k", "4k", "8k", "16k"][i]}</Text>
              </View>
            ))}
          </View>

          {/* EQ Presets */}
          <Text style={styles.presetSectionTitle}>MASTER PRESETS</Text>
          <View style={styles.presetsGrid}>
            {BUILT_IN_PRESETS.map((p) => (
              <Pressable
                key={p.id}
                onPress={() => {
                  Haptics.selection();
                  dsp.applyPreset(p.id);
                }}
                style={[styles.presetChip, dsp.presetId === p.id && styles.presetChipOn]}
              >
                <Text style={[styles.presetLabel, dsp.presetId === p.id && styles.presetLabelOn]}>{p.name}</Text>
              </Pressable>
            ))}
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: "row",
    gap: 12,
    alignItems: "center",
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
  kickerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
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
    letterSpacing: 1.4,
    fontFamily: font.sansBold,
  },
  title: {
    color: colors.text,
    fontSize: 18,
    fontWeight: "900",
    fontFamily: font.sansBold,
  },
  card: {
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    borderRadius: radius.xl,
    padding: 16,
    gap: 14,
    ...shadow.sm,
  },
  cardHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  cardHeaderBetween: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  cardTitle: {
    color: colors.text,
    fontWeight: "900",
    fontSize: 15,
    fontFamily: font.sansBold,
  },
  spatialVis: {
    height: 120,
    borderRadius: radius.lg,
    backgroundColor: "rgba(6,182,212,0.06)",
    borderWidth: 1,
    borderColor: "rgba(6,182,212,0.2)",
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
    overflow: "hidden",
  },
  soundRing: {
    position: "absolute",
    borderWidth: 1,
    borderColor: "rgba(6,182,212,0.15)",
  },
  spatialCenter: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: accent.aurora,
    alignItems: "center",
    justifyContent: "center",
    ...shadow.glow(accent.aurora, 0.5),
  },
  spatialDot: {
    position: "absolute",
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: "rgba(18,18,30,0.9)",
    borderWidth: 1.5,
    borderColor: accent.aurora,
    alignItems: "center",
    justifyContent: "center",
  },
  channelLabel: {
    color: accent.aurora,
    fontSize: 10,
    fontFamily: font.monoBold,
    fontWeight: "900",
  },
  spatialHint: {
    position: "absolute",
    bottom: 8,
    color: colors.textMuted,
    fontSize: 10,
    fontFamily: font.sansRegular,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  rowLabel: {
    width: 120,
    color: colors.textDim,
    fontSize: 12,
    fontFamily: font.sansMedium,
  },
  warnBox: {
    flexDirection: "row",
    gap: 8,
    alignItems: "center",
    backgroundColor: "rgba(251,191,36,0.12)",
    borderWidth: 1,
    borderColor: "rgba(251,191,36,0.3)",
    borderRadius: radius.md,
    padding: 10,
  },
  warnText: {
    flex: 1,
    color: "#FDE68A",
    fontSize: 11,
    lineHeight: 15,
    fontFamily: font.sansRegular,
  },
  toggle: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    paddingHorizontal: 12,
    height: 28,
    borderRadius: radius.xs,
    alignItems: "center",
    justifyContent: "center",
  },
  toggleOn: {
    backgroundColor: accent.primary,
    borderColor: accent.primary,
    ...shadow.glow(accent.primary, 0.4),
  },
  toggleLabel: {
    color: colors.textMuted,
    fontWeight: "900",
    fontSize: 10,
    fontFamily: font.sansBold,
    letterSpacing: 0.6,
  },
  toggleLabelOn: {
    color: "#fff",
  },
  chip: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    paddingHorizontal: 10,
    height: 28,
    borderRadius: radius.xs,
    alignItems: "center",
    justifyContent: "center",
  },
  chipOn: {
    backgroundColor: accent.primary,
    borderColor: accent.primary,
  },
  chipLabel: {
    color: colors.textMuted,
    fontWeight: "700",
    fontSize: 11,
    fontFamily: font.sansBold,
    textTransform: "uppercase",
  },
  chipLabelOn: {
    color: "#fff",
  },
  eqHint: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansRegular,
  },
  eqGrid: {
    flexDirection: "row",
    gap: 4,
    justifyContent: "space-between",
  },
  eqBand: {
    flex: 1,
    alignItems: "center",
    gap: 4,
  },
  eqGain: {
    color: colors.textMuted,
    fontSize: 10,
    fontWeight: "800",
    fontFamily: font.monoBold,
  },
  sliderVWrap: {
    height: 120,
    width: 24,
    alignItems: "center",
    justifyContent: "center",
  },
  eqLabel: {
    color: colors.textDim,
    fontSize: 9,
    fontWeight: "700",
    fontFamily: font.sansBold,
  },
  eqHz: {
    color: colors.textMuted,
    fontSize: 9,
    fontFamily: font.mono,
  },
  presetSectionTitle: {
    color: colors.textMuted,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 1.2,
    fontFamily: font.sansBold,
    marginTop: 6,
  },
  presetsGrid: {
    flexDirection: "row",
    gap: 8,
    flexWrap: "wrap",
  },
  presetChip: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: radius.xs,
  },
  presetChipOn: {
    backgroundColor: "rgba(139,92,246,0.22)",
    borderColor: accent.primary,
  },
  presetLabel: {
    color: colors.textDim,
    fontSize: 11,
    fontWeight: "700",
    fontFamily: font.sansMedium,
  },
  presetLabelOn: {
    color: "#fff",
    fontFamily: font.sansBold,
  },
});