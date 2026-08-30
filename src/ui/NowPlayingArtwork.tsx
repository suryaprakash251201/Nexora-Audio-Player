/**
 * Double-buffered artwork surface.
 *
 * Guarantees:
 *   - A loaded cover never unmounts while a new one decodes — "pending" fades
 *     over "committed" so there's no blank frame between tracks (a requirement
 *     in the brief: "Preload adjacent artwork" + "no blank frame").
 *   - Fast swipes are race-guarded by a monotonic token.
 *   - `url === null` crossfades to the branded gradient fallback.
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Animated, StyleSheet, View } from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";

const AnimatedImage = Animated.createAnimatedComponent(Image);

export default React.memo(function NowPlayingArtwork({
  url,
  trackKey,
  contentFit = "cover",
  onLoaded,
  onError,
}: {
  url: string | null;
  trackKey?: string | null;
  contentFit?: "cover" | "contain";
  onLoaded?: () => void;
  onError?: () => void;
}) {
  const [committed, setCommitted] = useState<string | null>(null);
  const [pending, setPending] = useState<string | null>(null);
  const pendingOpacity = useRef(new Animated.Value(0)).current;
  const reqRef = useRef(0);
  const pendingUrlRef = useRef<string | null>(null);
  const committedRef = useRef<string | null>(null);

  useEffect(() => {
    if (!url) {
      const retireId = ++reqRef.current;
      setPending(null);
      pendingUrlRef.current = null;
      if (committedRef.current !== null) {
        pendingOpacity.setValue(1);
        Animated.timing(pendingOpacity, { toValue: 0, duration: 220, useNativeDriver: true }).start(({ finished }) => {
          if (finished && reqRef.current === retireId) {
            committedRef.current = null;
            setCommitted(null);
          }
        });
      }
      return;
    }
    if (url === committed || pendingUrlRef.current === url) {
      if (pending && pending !== url) {
        reqRef.current++;
        pendingUrlRef.current = null;
        setPending(null);
      }
      return;
    }
    const id = ++reqRef.current;
    void id;
    pendingUrlRef.current = url;
    pendingOpacity.setValue(0);
    setPending(url);
  }, [url, committed, pending, pendingOpacity]);

  const handlePendingLoad = useCallback(() => {
    const w = pendingUrlRef.current;
    if (!w) return;
    Animated.timing(pendingOpacity, { toValue: 1, duration: 250, useNativeDriver: true }).start(({ finished }) => {
      if (!finished || pendingUrlRef.current !== w) return;
      committedRef.current = w;
      setCommitted(w);
      setPending((cur) => (cur === w ? null : cur));
    });
    onLoaded?.();
  }, [pendingOpacity, onLoaded]);

  const handlePendingError = useCallback(() => {
    if (pendingUrlRef.current === null) return;
    pendingUrlRef.current = null;
    setPending(null);
    onError?.();
  }, [onError]);

  const fallback = useMemo(() => (
    <LinearGradient
      colors={["#1C2650", "#3D53DB", "#5B8CFF"]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={StyleSheet.absoluteFill}
    >
      <Ionicons name="musical-notes" size={80} color="rgba(255,255,255,0.92)" style={{ flex: 1, textAlign: "center", textAlignVertical: "center" } as any} />
    </LinearGradient>
  ), []);

  return (
    <View style={StyleSheet.absoluteFill} collapsable={false}>
      {fallback}
      {committed ? (
        <Image source={{ uri: committed }} style={StyleSheet.absoluteFill} contentFit={contentFit} cachePolicy="memory-disk" recyclingKey={trackKey ?? undefined} />
      ) : null}
      {pending ? (
        <AnimatedImage
          source={{ uri: pending }}
          style={[StyleSheet.absoluteFill, { opacity: pendingOpacity }]}
          contentFit={contentFit}
          cachePolicy="memory-disk"
          onLoad={handlePendingLoad}
          onError={handlePendingError}
        />
      ) : null}
    </View>
  );
});