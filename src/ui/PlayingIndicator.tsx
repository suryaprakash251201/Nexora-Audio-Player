import React, { useEffect } from "react";
import { View, StyleSheet } from "react-native";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withDelay,
  withSequence,
  Easing,
} from "react-native-reanimated";
import { colors } from "@/ui/theme";

type Props = {
  playing?: boolean;
  color?: string;
  size?: number;
};

function Bar({ delay, playing, color, maxH }: { delay: number; playing: boolean; color: string; maxH: number }) {
  const h = useSharedValue(playing ? maxH * 0.4 : maxH * 0.2);

  useEffect(() => {
    if (playing) {
      h.value = withDelay(
        delay,
        withRepeat(
          withSequence(
            withTiming(maxH, { duration: 300 + delay, easing: Easing.inOut(Easing.ease) }),
            withTiming(maxH * 0.2, { duration: 400 + delay, easing: Easing.inOut(Easing.ease) }),
          ),
          -1,
          true,
        ),
      );
    } else {
      h.value = withTiming(maxH * 0.2, { duration: 300 });
    }
  }, [playing, delay, maxH]);

  const style = useAnimatedStyle(() => ({ height: h.value }));

  return (
    <Animated.View
      style={[
        {
          width: 3,
          borderRadius: 1.5,
          backgroundColor: color,
        },
        style,
      ]}
    />
  );
}

export function PlayingIndicator({ playing = true, color = colors.accent, size = 16 }: Props) {
  return (
    <View style={[styles.root, { width: size, height: size }]}>
      <Bar delay={0} playing={playing} color={color} maxH={size} />
      <Bar delay={100} playing={playing} color={color} maxH={size} />
      <Bar delay={200} playing={playing} color={color} maxH={size} />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "flex-end",
    justifyContent: "center",
    gap: 2,
  },
});
