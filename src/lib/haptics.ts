/**
 * Haptics wrapper. Falls back gracefully when expo-haptics isn't linked yet
 * (M1 didn't import it; M20 does, and the wrapper keeps every call site safe).
 */
import * as HapticsNative from "expo-haptics";

export const Haptics = {
  available: !!HapticsNative,
  tapLight() {
    try { HapticsNative.impactAsync(HapticsNative.ImpactFeedbackStyle.Light).catch(() => {}); } catch {}
  },
  tapMedium() {
    try { HapticsNative.impactAsync(HapticsNative.ImpactFeedbackStyle.Medium).catch(() => {}); } catch {}
  },
  success() {
    try { HapticsNative.notificationAsync(HapticsNative.NotificationFeedbackType.Success).catch(() => {}); } catch {}
  },
  warning() {
    try { HapticsNative.notificationAsync(HapticsNative.NotificationFeedbackType.Warning).catch(() => {}); } catch {}
  },
  error() {
    try { HapticsNative.notificationAsync(HapticsNative.NotificationFeedbackType.Error).catch(() => {}); } catch {}
  },
  selection() {
    try { HapticsNative.selectionAsync().catch(() => {}); } catch {}
  },
};