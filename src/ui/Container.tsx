import React, { ReactNode } from "react";
import { StyleSheet, View, ViewStyle } from "react-native";
import { colors, spacing } from "@/ui/theme";
import { useLayout } from "@/ui/layout";

/**
 * Responsive container — clamps content to `contentMaxWidth` and centers it.
 * Use on every screen so on tablet/desktop the content doesn't span edge to
 * edge and the design feels intentional.
 */
export function Container({
  children,
  style,
  padded = true,
  background,
}: {
  children: ReactNode;
  style?: ViewStyle | ViewStyle[];
  padded?: boolean;
  background?: string;
}) {
  const { contentMaxWidth } = useLayout();
  return (
    <View style={[styles.outer, background ? { backgroundColor: background } : null]}>
      <View
        style={[
          styles.inner,
          padded ? { paddingHorizontal: spacing.lg } : null,
          { maxWidth: contentMaxWidth },
          style as any,
        ]}
      >
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  outer: { flex: 1, backgroundColor: colors.bg, width: "100%" },
  inner: { flex: 1, alignSelf: "center", width: "100%" },
});