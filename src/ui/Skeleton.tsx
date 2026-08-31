import React, { useEffect } from "react";
import { StyleSheet, View, ViewStyle } from "react-native";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  Easing,
} from "react-native-reanimated";
import { radius } from "@/ui/theme";

type SkeletonProps = {
  width?: number | string;
  height?: number;
  borderRadius?: number;
  style?: ViewStyle;
};

export function Skeleton({ width = "100%", height = 16, borderRadius = radius.sm, style }: SkeletonProps) {
  const opacity = useSharedValue(0.3);

  useEffect(() => {
    opacity.value = withRepeat(
      withTiming(0.7, { duration: 900, easing: Easing.inOut(Easing.ease) }),
      -1,
      true,
    );
  }, []);

  const animStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <Animated.View
      style={[
        {
          width: width as any,
          height,
          borderRadius,
          backgroundColor: "rgba(255,255,255,0.08)",
        },
        animStyle,
        style,
      ]}
    />
  );
}

export function SkeletonTrackRow() {
  return (
    <View style={skStyles.row}>
      <Skeleton width={52} height={52} borderRadius={10} />
      <View style={skStyles.texts}>
        <Skeleton width="70%" height={14} />
        <Skeleton width="50%" height={12} />
        <Skeleton width="30%" height={10} />
      </View>
    </View>
  );
}

export function SkeletonAlbumCard({ width = 168 }: { width?: number }) {
  return (
    <View style={{ width, gap: 8 }}>
      <Skeleton width={width} height={width} borderRadius={18} />
      <Skeleton width="80%" height={13} />
      <Skeleton width="50%" height={11} />
    </View>
  );
}

export function SkeletonList({ count = 5 }: { count?: number }) {
  return (
    <View style={{ gap: 4 }}>
      {Array.from({ length: count }).map((_, i) => (
        <SkeletonTrackRow key={i} />
      ))}
    </View>
  );
}

const skStyles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 12,
  },
  texts: { flex: 1, gap: 6 },
});
