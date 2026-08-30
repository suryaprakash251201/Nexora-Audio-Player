import React, { useCallback, useRef } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import { colors } from "@/ui/theme";

/**
 * Minimal JS slider — avoids the native `@react-native-community/slider`
 * until the native audio modules need it. Works on web via Pressable
 * locationX.
 */
export function Slider({
  value,
  minimumValue,
  maximumValue,
  step = 1,
  onValueChange,
  style,
}: {
  value: number;
  minimumValue: number;
  maximumValue: number;
  step?: number;
  onValueChange: (v: number) => void;
  style?: any;
  minimumTrackTintColor?: string;
  maximumTrackTintColor?: string;
  thumbTintColor?: string;
}) {
  const widthRef = useRef(0);
  const range = maximumValue - minimumValue;
  const ratio = range === 0 ? 0 : (value - minimumValue) / range;

  const quantize = useCallback((v: number) => {
    if (!step || step <= 0) return v;
    return Math.round(v / step) * step;
  }, [step]);

  const handleMove = useCallback((x: number, w: number) => {
    if (w <= 0) return;
    const r = Math.max(0, Math.min(1, x / w));
    const raw = minimumValue + r * range;
    onValueChange(quantize(Math.max(minimumValue, Math.min(maximumValue, raw))));
  }, [minimumValue, maximumValue, range, quantize, onValueChange]);

  const pan = Gesture.Pan()
    .onUpdate((e) => {
      // gesture-handler pan provides translation; we use absolute x via event? Fallback to press.
    })
    .runOnJS(true);

  return (
    <View style={[styles.wrap, style]} onLayout={(e) => { widthRef.current = e.nativeEvent.layout.width; }}>
      <Pressable
        style={styles.hit}
        onPress={(e) => {
          const x = (e.nativeEvent as any).locationX ?? 0;
          handleMove(x, widthRef.current || 200);
        }}
      >
        {/* track */}
        <View style={styles.track}>
          <View style={[styles.fill, { flex: ratio, backgroundColor: colors.accent }]} />
          <View style={{ flex: 1 - ratio, backgroundColor: "rgba(255,255,255,0.12)" }} />
        </View>
        {/* thumb */}
        <View style={[styles.thumb, { left: `${ratio * 100}%` as any, backgroundColor: colors.accent }]} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { height: 28, justifyContent: "center" },
  hit: { height: 28, justifyContent: "center" },
  track: { height: 4, borderRadius: 2, flexDirection: "row", overflow: "hidden" },
  fill: { borderRadius: 2 },
  thumb: { position: "absolute", top: 8, width: 14, height: 14, borderRadius: 7, marginLeft: -7, borderWidth: 2, borderColor: "#fff", elevation: 2 },
});