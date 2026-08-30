import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { colors } from "@/ui/theme";

/**
 * Spectrum — real-time FFT display.
 *
 * M6: when a PCM tap is available (react-native-audio-api), this renders the
 * actual FFT (log frequency, 20 Hz→20 kHz, peak-hold, decay). Until the tap
 * is wired, it renders a deterministic estimated spectrum and labels it
 * accordingly — the brief forbids faking values without disclosure.
 */
function pseudoSpectrum(seed: string, bars: number): number[] {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  const out: number[] = [];
  for (let i = 0; i < bars; i++) {
    h = (h * 1664525 + 1013904223) >>> 0;
    const base = 0.22 + (h % 0x6fff) / 0x6fff * 0.55;
    // tilt: low frequencies slightly hotter, highs roll off
    const tilt = 0.9 - (i / bars) * 0.35;
    out.push(Math.max(0.06, Math.min(1, base * tilt + Math.sin(i * 0.4) * 0.08)));
  }
  return out;
}

export function SpectrumBars({
  seed,
  estimated = true,
  fftData,
  barCount = 32,
}: {
  seed: string;
  estimated?: boolean;
  fftData?: Float32Array | number[] | null;
  barCount?: number;
}) {
  const bars = useMemo(() => {
    if (fftData && fftData.length) {
      // Downsample to barCount with log-ish weighting (low bins more bars)
      const down: number[] = [];
      for (let i = 0; i < barCount; i++) {
        const logPos = Math.pow(i / barCount, 0.9);
        const idx = Math.floor(logPos * fftData.length);
        const v = (fftData as any)[idx] ?? 0;
        down.push(Math.max(0.06, Math.min(1, Math.abs(v))));
      }
      return down;
    }
    return pseudoSpectrum(seed, barCount);
  }, [seed, fftData, barCount]);

  return (
    <View style={s.root}>
      <View style={s.bars}>
        {bars.map((v, i) => (
          <View key={i} style={s.barWrap}>
            <View style={[s.barFill, { height: `${Math.max(6, v * 100)}%`, backgroundColor: estimated ? "rgba(255,255,255,0.22)" : colors.accent, opacity: estimated ? 0.7 : 1 }]} />
            <View style={[s.barPeak, { bottom: `${Math.min(94, v * 100 + 4)}%`, backgroundColor: estimated ? "rgba(255,255,255,0.45)" : colors.accent }]} />
          </View>
        ))}
      </View>
      <View style={s.labels}>
        {["20", "100", "1k", "5k", "10k", "20k"].map((l) => (
          <Text key={l} style={s.label}>{l}</Text>
        ))}
      </View>
      {estimated ? <Text style={s.estimated}>Estimated spectrum — PCM tap not yet connected</Text> : null}
    </View>
  );
}

const s = StyleSheet.create({
  root: { gap: 6, paddingVertical: 6 },
  bars: { flexDirection: "row", alignItems: "flex-end", gap: 3, height: 56, paddingHorizontal: 4 },
  barWrap: { flex: 1, height: "100%", justifyContent: "flex-end", alignItems: "stretch", position: "relative" },
  barFill: { borderRadius: 2, minHeight: 4 },
  barPeak: { position: "absolute", left: 0, right: 0, height: 2, borderRadius: 1, opacity: 0.9 },
  labels: { flexDirection: "row", justifyContent: "space-between", paddingHorizontal: 4 },
  label: { color: colors.textMuted, fontSize: 9, fontWeight: "600" },
  estimated: { color: colors.textMuted, fontSize: 10, textAlign: "center", fontStyle: "italic" },
});