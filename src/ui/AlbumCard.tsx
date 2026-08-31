import React, { memo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius } from "@/ui/theme";
import { Haptics } from "@/lib/haptics";

/**
 * AlbumCard — used on Home and in Albums grids.
 */
function AlbumCardInner({
  title,
  subtitle,
  count,
  cover,
  onPress,
  width = 168,
}: {
  title: string;
  subtitle: string;
  count: number;
  cover: string | null;
  onPress: () => void;
  width?: number;
}) {
  return (
    <Pressable onPress={() => { Haptics.tapLight(); onPress(); }} style={[styles.root, { width }]}>
      <View style={[styles.art, { width, height: width }]}>
        {cover ? (
          <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
        ) : (
          <LinearGradient colors={["#1C2650", "#5B8CFF", "#8B5CF6"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
        )}
        <LinearGradient colors={["rgba(0,0,0,0)", "rgba(0,0,0,0.55)"]} style={StyleSheet.absoluteFill} />
        <View style={styles.qualityStripe}>
          <Text style={styles.qualityStripeText}>ALBUM</Text>
        </View>
      </View>
      <View style={styles.texts}>
        <Text numberOfLines={1} style={styles.title}>{title}</Text>
        <Text numberOfLines={1} style={styles.subtitle}>{subtitle}</Text>
        <Text style={styles.count}>{count} tracks</Text>
      </View>
    </Pressable>
  );
}

export const AlbumCard = memo(AlbumCardInner);

/** Round artist card. */
export const ArtistCard = memo(function ArtistCard({
  name,
  count,
  cover,
  onPress,
  size = 132,
}: {
  name: string;
  count: number;
  cover: string | null;
  onPress: () => void;
  size?: number;
}) {
  return (
    <Pressable onPress={() => { Haptics.tapLight(); onPress(); }} style={{ width: size }}>
      <View style={[styles.artistArt, { width: size, height: size }]}>
        {cover ? (
          <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
        ) : (
          <LinearGradient colors={["#2A2A3A", "#444", "#7C3AED"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
        )}
        <LinearGradient colors={["rgba(0,0,0,0)", "rgba(0,0,0,0.4)"]} style={StyleSheet.absoluteFill} />
        <View style={styles.artistNameWrap}>
          <Text numberOfLines={1} style={styles.artistName}>{name}</Text>
          <Text style={styles.artistCount}>{count} tracks</Text>
        </View>
      </View>
    </Pressable>
  );
});

/** Folder card — shows folder cover + file count. */
export const FolderCard = memo(function FolderCard({
  name,
  path,
  count,
  cover,
  onPress,
  width = 168,
}: {
  name: string;
  path: string;
  count: number;
  cover: string | null;
  onPress: () => void;
  width?: number;
}) {
  return (
    <Pressable onPress={() => { Haptics.tapLight(); onPress(); }} style={[styles.root, { width }]}>
      <View style={[styles.art, { width, height: width }]}>
        {cover ? (
          <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
        ) : (
          <LinearGradient colors={["#1E293B", "#334155", "#475569"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
        )}
        <LinearGradient colors={["rgba(0,0,0,0)", "rgba(0,0,0,0.55)"]} style={StyleSheet.absoluteFill} />
        <View style={styles.folderIconBadge}>
          <Ionicons name="folder" size={14} color="#fff" />
        </View>
        <View style={[styles.qualityStripe, { backgroundColor: "rgba(59,130,246,0.85)" }]}>
          <Text style={styles.qualityStripeText}>FOLDER</Text>
        </View>
      </View>
      <View style={styles.texts}>
        <Text numberOfLines={1} style={styles.title}>{name}</Text>
        <Text numberOfLines={1} style={styles.subtitle}>{path}</Text>
        <Text style={styles.count}>{count} tracks</Text>
      </View>
    </Pressable>
  );
});

const styles = StyleSheet.create({
  root: { gap: 8 },
  art: {
    borderRadius: radius.lg,
    overflow: "hidden",
    backgroundColor: "#16161F",
    borderWidth: 1,
    borderColor: colors.hairline,
    justifyContent: "flex-end",
  },
  qualityStripe: { position: "absolute", top: 8, left: 8, paddingHorizontal: 6, paddingVertical: 2, backgroundColor: "rgba(0,0,0,0.45)", borderRadius: 4, borderWidth: 1, borderColor: "rgba(255,255,255,0.18)" },
  qualityStripeText: { color: "#fff", fontSize: 9, fontWeight: "800", letterSpacing: 0.6, fontFamily: font.sansBold },
  folderIconBadge: { position: "absolute", bottom: 10, right: 10, width: 28, height: 28, borderRadius: 14, backgroundColor: "rgba(59,130,246,0.9)", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: "rgba(255,255,255,0.2)" },
  texts: { gap: 1, paddingHorizontal: 2 },
  title: { color: colors.text, fontSize: 13, fontWeight: "700", fontFamily: font.sansBold },
  subtitle: { color: colors.textMuted, fontSize: 11, fontFamily: font.sansRegular },
  count: { color: colors.textMuted, fontSize: 10, fontWeight: "700", marginTop: 2, fontFamily: font.sansMedium, letterSpacing: 0.4, textTransform: "uppercase" },
  artistArt: { borderRadius: 999, overflow: "hidden", backgroundColor: "#1E1E2A", borderWidth: 1, borderColor: colors.hairline, justifyContent: "flex-end" },
  artistNameWrap: { paddingHorizontal: 10, paddingBottom: 10, gap: 2 },
  artistName: { color: "#fff", fontSize: 13, fontWeight: "800", fontFamily: font.sansBold },
  artistCount: { color: "rgba(255,255,255,0.75)", fontSize: 10, fontWeight: "700", letterSpacing: 0.4, textTransform: "uppercase", fontFamily: font.sansMedium },
});