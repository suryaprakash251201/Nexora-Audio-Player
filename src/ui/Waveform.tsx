import React, { useMemo } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { colors } from "@/ui/theme";

/**
 * Lightweight waveform / seek bar.
 *
 * For M6 we synthesize a placeholder waveform from the file size + duration
 * when a real PCM decode isn't available (so the bar is always usable for
 * seeking). When a real waveform (Float32Array) is supplied, it renders that.
 * No fake analyzer values — bars are deterministic from the same seed.
 */

function pseudoBars(seed: string, count: number): number[] {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  const out: number[] = [];
  for (let i = 0; i < count; i++) {
    h = (h * 1664525 + 1013904223) >>> 0;
    const v = 0.18 + (h % 0x7fff) / 0x7fff * 0.82;
    // gentle bell curve so edges taper
    const taper = Math.sin((i / count) * Math.PI);
    out.push(v * (0.35 + 0.65 * taper));
  }
  return out;
}

export function WaveformSeekBar({
  progress, // 0..1
  duration,
  seed,
  waveform, // optional Float32Array 0..1
  onSeek,
}: {
  progress: number;
  duration: number;
  seed: string;
  waveform?: Float32Array | number[] | null;
  onSeek: (ratio: number) => void;
}) {
  const bars = useMemo(() => {
    if (waveform && waveform.length) {
      const step = waveform.length / 64;
      const down: number[] = [];
      for (let i = 0; i < 64; i++) {
        let sum = 0;
        const from = Math.floor(i * step);
        const to = Math.floor((i + 1) * step);
        for (let j = from; j < to; j++) sum += Math.abs((waveform as any)[j] ?? 0);
        const len = Math.max(1, to - from);
        down.push(Math.min(1, Math.max(0.08, sum / len)));
      }
      return down;
    }
    return pseudoBars(seed || "wave", 64);
  }, [seed, waveform]);

  const w = 320;
  const h = 36;
  const gap = 2;
  const barW = (w - gap * (bars.length - 1)) / bars.length;

  const clamped = Math.max(0, Math.min(1, progress));

  return (
    <Pressable
      onPress={(e) => {
        const locX = (e.nativeEvent as any).locationX ?? 0;
        onSeek(Math.max(0, Math.min(1, locX / w)));
      }}
      style={styles.root}
    >
      <View style={{ width: w, height: h, flexDirection: "row", alignItems: "center", gap }}>
        {bars.map((v, i) => {
          const active = i / bars.length <= clamped;
          const bh = Math.max(3, v * h);
          return (
            <View
              key={i}
              style={{
                width: barW,
                height: bh,
                borderRadius: 2,
                backgroundColor: active ? colors.accent : "rgba(255,255,255,0.18)",
                opacity: active ? 1 : 0.65,
              }}
            />
          );
        })}
      </View>
      {/* time labels sit outside svg; parent owns them */}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { alignItems: "center", justifyContent: "center", paddingVertical: 6 },
});