import React, { useRef } from "react";
import { Animated, Pressable, PressableProps, ViewStyle } from "react-native";

type Props = PressableProps & {
  scaleTo?: number;
  style?: ViewStyle | ((state: { pressed: boolean }) => ViewStyle);
  haptic?: boolean;
  children: React.ReactNode;
};

/**
 * AnimatedPressable — opinionated pressable that scales subtly on press
 * and supports a press-time haptic on iOS/Android. Replaces the hundreds
 * of inline `Pressable` usages so the M20 polish wave is one import away.
 */
import { Haptics } from "@/lib/haptics";

export function AnimatedPressable({ scaleTo = 0.96, style, onPressIn, onPressOut, haptic, children, ...rest }: Props) {
  const scale = useRef(new Animated.Value(1)).current;
  const handleIn = (e: any) => {
    Animated.timing(scale, { toValue: scaleTo, duration: 90, useNativeDriver: true }).start();
    if (haptic) Haptics.tapLight();
    onPressIn?.(e);
  };
  const handleOut = (e: any) => {
    Animated.timing(scale, { toValue: 1, duration: 140, useNativeDriver: true }).start();
    onPressOut?.(e);
  };
  return (
    <Animated.View style={{ transform: [{ scale }] }}>
      <Pressable
        {...rest}
        onPressIn={handleIn}
        onPressOut={handleOut}
        style={typeof style === "function" ? style : style}
      >
        {children}
      </Pressable>
    </Animated.View>
  );
}