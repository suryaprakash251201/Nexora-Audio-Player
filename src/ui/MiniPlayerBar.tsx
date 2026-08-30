import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { colors } from "@/ui/theme";
import { usePlayback } from "@/store/PlaybackContext";

export default function MiniPlayerBar() {
  const p = usePlayback();
  const cur = p.current;
  if (!cur) return null;

  const onExpand = () => {
    router.push({ pathname: "/track/[id]", params: { id: encodeURIComponent(cur.id) } });
  };

  return (
    <Pressable onPress={onExpand} style={s.root}>
      <View style={s.art}>
        {cur.artwork.url ? (
          <Image source={{ uri: cur.artwork.url }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
        ) : (
          <View style={[StyleSheet.absoluteFill, { backgroundColor: "#1E1E2A", alignItems: "center", justifyContent: "center" }]}>
            <Ionicons name="musical-notes" size={16} color="rgba(255,255,255,0.7)" />
          </View>
        )}
      </View>
      <View style={{ flex: 1, minWidth: 0, gap: 1 }}>
        <Text numberOfLines={1} style={s.title}>{cur.title}</Text>
        <Text numberOfLines={1} style={s.sub}>{cur.artist ?? cur.album ?? cur.metadata.codec as string}</Text>
      </View>
      <Pressable onPress={() => void p.toggle()} hitSlop={10} style={s.btn}>
        <Ionicons name={p.playing ? "pause" : "play"} size={18} color={colors.text} />
      </Pressable>
      <Pressable onPress={() => void p.next()} hitSlop={10} style={s.btnGhost}>
        <Ionicons name="play-skip-forward" size={18} color={colors.textDim} />
      </Pressable>
      <Pressable onPress={() => void p.close()} hitSlop={10} style={s.btnGhost}>
        <Ionicons name="close" size={16} color={colors.textMuted} />
      </Pressable>
    </Pressable>
  );
}

const s = StyleSheet.create({
  root: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 10,
    paddingVertical: 8,
    paddingBottom: 10,
    backgroundColor: colors.bgRaised,
    borderTopWidth: 1,
    borderTopColor: colors.hairline,
  },
  art: { width: 44, height: 44, borderRadius: 8, overflow: "hidden", backgroundColor: "#1C1C27" },
  title: { color: colors.text, fontSize: 13, fontWeight: "700" },
  sub: { color: colors.textMuted, fontSize: 11 },
  btn: { width: 36, height: 36, borderRadius: 18, backgroundColor: "rgba(255,255,255,0.08)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  btnGhost: { width: 36, height: 36, alignItems: "center", justifyContent: "center" },
});