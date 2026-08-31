/**
 * Responsive layout primitives (M24).
 *
 * - `useBreakpoint()`: phone vs tablet vs wide (window-width based).
 * - `useLayout()`: orientation + width + a small "content max width" helper
 *   so screens can switch to a 2-column layout on iPad.
 * - `contentMaxWidth`: 720 on phone, 960 on tablet portrait, 1180 on
 *   tablet landscape / desktop. Every centered surface should clamp to it.
 * - `gridColumns`: 1 on phone, 2 on tablet portrait, 3 on tablet landscape,
 *   4 on desktop. Library / albums / artists use this to switch from
 *   vertical lists to masonry-ish grids.
 */
import { useEffect, useState } from "react";
import { Dimensions, useWindowDimensions } from "react-native";

export type Breakpoint = "phone" | "tabletP" | "tabletL" | "desktop";

export function getBreakpoint(width: number): Breakpoint {
  if (width >= 1100) return "desktop";
  if (width >= 900) return "tabletL";
  if (width >= 600) return "tabletP";
  return "phone";
}

export function useBreakpoint(): Breakpoint {
  const { width } = useWindowDimensions();
  return getBreakpoint(width);
}

export function useLayout() {
  const { width, height, scale, fontScale } = useWindowDimensions();
  const bp = getBreakpoint(width);
  const isLandscape = width > height;
  const isTablet = bp !== "phone";
  const isDesktop = bp === "desktop";
  const contentMaxWidth = bp === "phone" ? 720 : bp === "tabletP" ? 880 : bp === "tabletL" ? 1080 : 1240;
  const gridColumns = bp === "phone" ? (isLandscape ? 2 : 1) : bp === "tabletP" ? 2 : bp === "tabletL" ? 3 : 4;
  const albumColumns = bp === "phone" ? (isLandscape ? 3 : 2) : bp === "tabletP" ? 3 : bp === "tabletL" ? 4 : 5;
  const artistColumns = bp === "phone" ? 1 : bp === "tabletP" ? 2 : bp === "tabletL" ? 2 : 3;
  return { width, height, scale, fontScale, bp, isLandscape, isTablet, isDesktop, contentMaxWidth, gridColumns, albumColumns, artistColumns };
}

/**
 * Two-column responsive container. On phone, content stacks; on tablet
 * portrait+ it splits into a main + sidebar (typical iPad/tablet layout).
 */
export function useTwoColumnLayout(sidebarWidth = 320) {
  const { bp, width } = useLayout();
  const split = bp !== "phone" && width >= 720;
  return { split, sidebarWidth };
}

/** Resize-aware: re-render once when the dimensions change. */
export function useDimensionsChange(): { width: number; height: number } {
  const { width, height } = useWindowDimensions();
  const [d, setD] = useState({ width, height });
  useEffect(() => { setD({ width, height }); }, [width, height]);
  return d;
}

/** Scaled icon sizes per breakpoint (so tablet doesn't feel toy-sized). */
export function useIconScale(): { sm: number; md: number; lg: number; xl: number } {
  const { bp } = useLayout();
  const mul = bp === "phone" ? 1 : bp === "tabletP" ? 1.08 : bp === "tabletL" ? 1.12 : 1.15;
  return { sm: 16 * mul, md: 22 * mul, lg: 28 * mul, xl: 36 * mul };
}