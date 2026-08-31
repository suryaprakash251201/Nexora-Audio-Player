import React, { useCallback, useRef, useEffect } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, { useSharedValue, useAnimatedStyle, runOnJS } from "react-native-reanimated";
import { colors } from "@/ui/theme";
import { Haptics } from "@/lib/haptics";

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
  minimumTrackTintColor,
  maximumTrackTintColor,
  thumbTintColor,
  accessibilityLabel,
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
  accessibilityLabel?: string;
}) {
  const widthRef = useRef(0);
  const range = maximumValue - minimumValue;
  const ratio = range === 0 ? 0 : (value - minimumValue) / range;

  const isDragging = useSharedValue(false);
  const lastHaptic = useSharedValue(0);
  const activeRatio = useSharedValue(ratio);

  useEffect(() => {
    // If we're not actively dragging, keep the visual activeRatio in sync with the prop
    if (!isDragging.value) {
      activeRatio.value = ratio;
    }
  }, [ratio]);

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

  const triggerHaptic = useCallback(() => {
    Haptics.selection();
  }, []);

  const pan = Gesture.Pan()
    .onBegin(() => {
      isDragging.value = true;
    })
    .onUpdate((e) => {
      const w = widthRef.current;
      if (w <= 0) return;
      const x = e.x;
      const r = Math.max(0, Math.min(1, x / w));
      activeRatio.value = r;

      const pct = r * 100;
      let hapticPoint = 0;
      if (pct >= 25 && pct < 50) hapticPoint = 25;
      else if (pct >= 50 && pct < 75) hapticPoint = 50;
      else if (pct >= 75 && pct < 100) hapticPoint = 75;

      if (hapticPoint !== 0 && hapticPoint !== lastHaptic.value) {
        lastHaptic.value = hapticPoint;
        runOnJS(triggerHaptic)();
      } else if (pct < 25) {
        lastHaptic.value = 0;
      }

      runOnJS(handleMove)(x, w);
    })
    .onEnd(() => {
      isDragging.value = false;
    })
    .onFinalize(() => {
      isDragging.value = false;
    });

  const fillStyle = useAnimatedStyle(() => ({
    flex: activeRatio.value,
  }));

  const remainingStyle = useAnimatedStyle(() => ({
    flex: 1 - activeRatio.value,
  }));

  const thumbStyle = useAnimatedStyle(() => ({
    left: `${activeRatio.value * 100}%`,
  }));

  return (
    <View 
      style={[styles.wrap, style]} 
      onLayout={(e) => { widthRef.current = e.nativeEvent.layout.width; }}
      accessibilityRole="adjustable"
      accessibilityValue={{ min: minimumValue, max: maximumValue, now: value }}
      accessibilityLabel={accessibilityLabel}
    >
      <GestureDetector gesture={pan}>
        <Pressable
          style={styles.hit}
          onPress={(e) => {
            const x = (e.nativeEvent as any).locationX ?? 0;
            handleMove(x, widthRef.current || 200);
          }}
        >
          {/* track */}
          <View style={styles.track}>
            <Animated.View style={[styles.fill, fillStyle, { backgroundColor: minimumTrackTintColor || colors.accent }]} />
            <Animated.View style={[remainingStyle, { backgroundColor: maximumTrackTintColor || "rgba(255,255,255,0.12)" }]} />
          </View>
          {/* thumb */}
          <Animated.View style={[styles.thumb, thumbStyle, { backgroundColor: thumbTintColor || colors.accent }]} />
          
          {/* Invisible touch area for the thumb (44x44) centered on the thumb */}
          <Animated.View style={[styles.thumbHitArea, thumbStyle]} pointerEvents="none" />
        </Pressable>
      </GestureDetector>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { height: 44, justifyContent: "center" },
  hit: { height: 44, justifyContent: "center" },
  track: { height: 4, borderRadius: 2, flexDirection: "row", overflow: "hidden" },
  fill: { borderRadius: 2 },
  thumb: { position: "absolute", top: 15, width: 14, height: 14, borderRadius: 7, marginLeft: -7, borderWidth: 2, borderColor: "#fff", elevation: 2 },
  thumbHitArea: { position: "absolute", top: 0, width: 44, height: 44, marginLeft: -22, backgroundColor: "transparent" },
});