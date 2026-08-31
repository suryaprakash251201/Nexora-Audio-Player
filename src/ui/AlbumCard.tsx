import React, { memo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, radius, shadow, tierColor, accent } from "@/ui/theme";
import { Haptics } from "@/lib/haptics";

/**
 * AlbumCard — Studio Vinyl Sleeve + Disc Preview.
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
    <Pressable
      onPress={() => {
        Haptics.tapLight();
        onPress();
      }}
      style={({ pressed }) => [styles.root, { width }, pressed && { opacity: 0.88, transform: [{ scale: 0.98 }] }]}
    >
      <View style={[styles.sleeveContainer, { width, height: width }]}>
        {/* Vinyl Disc peeking out behind the cover sleeve */}
        <View style={[styles.vinylDisc, { width: width * 0.94, height: width * 0.94, borderRadius: (width * 0.94) / 2 }]}>
          <View style={[styles.vinylGroove, { width: width * 0.7, height: width * 0.7, borderRadius: (width * 0.7) / 2 }]} />
          <View style={[styles.vinylGroove, { width: width * 0.45, height: width * 0.45, borderRadius: (width * 0.45) / 2 }]} />
          <View style={[styles.vinylCenter, { width: width * 0.26, height: width * 0.26, borderRadius: (width * 0.26) / 2 }]}>
            <View style={styles.spindle} />
          </View>
        </View>

        {/* Cover Sleeve */}
        <View style={[styles.art, { width, height: width }]}>
          {cover ? (
            <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
          ) : (
            <LinearGradient
              colors={["#1E1B4B", "#4338CA", "#8B5CF6"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />
          )}
          <LinearGradient colors={["rgba(0,0,0,0)", "rgba(6,6,10,0.68)"]} style={StyleSheet.absoluteFill} />

          {/* Studio Album Tag */}
          <View style={styles.qualityStripe}>
            <Ionicons name="disc-outline" size={10} color="#FBBF24" />
            <Text style={styles.qualityStripeText}>ALBUM</Text>
          </View>
        </View>
      </View>

      <View style={styles.texts}>
        <Text numberOfLines={1} style={styles.title}>{title}</Text>
        <Text numberOfLines={1} style={styles.subtitle}>{subtitle}</Text>
        <View style={styles.countBadge}>
          <Text style={styles.count}>{count} TRACKS</Text>
        </View>
      </View>
    </Pressable>
  );
}

export const AlbumCard = memo(AlbumCardInner);

/** Round artist card with neon ring. */
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
    <Pressable
      onPress={() => {
        Haptics.tapLight();
        onPress();
      }}
      style={({ pressed }) => [{ width: size, alignItems: "center" }, pressed && { opacity: 0.88, transform: [{ scale: 0.97 }] }]}
    >
      <View style={[styles.artistRing, { width: size, height: size, borderRadius: size / 2 }]}>
        <View style={[styles.artistArt, { width: size - 6, height: size - 6, borderRadius: (size - 6) / 2 }]}>
          {cover ? (
            <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
          ) : (
            <LinearGradient colors={["#2E1065", "#7C3AED", "#06B6D4"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
          )}
          <LinearGradient colors={["rgba(0,0,0,0)", "rgba(6,6,10,0.6)"]} style={StyleSheet.absoluteFill} />
        </View>
      </View>
      <View style={styles.artistTexts}>
        <Text numberOfLines={1} style={styles.artistName}>{name}</Text>
        <Text style={styles.artistCount}>{count} TRACKS</Text>
      </View>
    </Pressable>
  );
});

/** Folder card with breadcrumb path preview. */
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
    <Pressable
      onPress={() => {
        Haptics.tapLight();
        onPress();
      }}
      style={({ pressed }) => [styles.root, { width }, pressed && { opacity: 0.88, transform: [{ scale: 0.98 }] }]}
    >
      <View style={[styles.art, { width, height: width }]}>
        {cover ? (
          <Image source={{ uri: cover }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
        ) : (
          <LinearGradient colors={["#0F172A", "#1E293B", "#334155"]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={StyleSheet.absoluteFill} />
        )}
        <LinearGradient colors={["rgba(0,0,0,0)", "rgba(6,6,10,0.72)"]} style={StyleSheet.absoluteFill} />

        <View style={styles.folderIconBadge}>
          <Ionicons name="folder-open" size={14} color="#38BDF8" />
        </View>
        <View style={[styles.qualityStripe, { backgroundColor: "rgba(56,189,248,0.2)", borderColor: "rgba(56,189,248,0.4)" }]}>
          <Text style={[styles.qualityStripeText, { color: "#38BDF8" }]}>FOLDER</Text>
        </View>
      </View>
      <View style={styles.texts}>
        <Text numberOfLines={1} style={styles.title}>{name}</Text>
        <Text numberOfLines={1} style={styles.subtitle}>{path}</Text>
        <View style={styles.countBadge}>
          <Text style={styles.count}>{count} TRACKS</Text>
        </View>
      </View>
    </Pressable>
  );
});

const styles = StyleSheet.create({
  root: { gap: 8 },
  sleeveContainer: {
    position: "relative",
    justifyContent: "center",
    alignItems: "center",
  },
  vinylDisc: {
    position: "absolute",
    right: -6,
    top: 4,
    backgroundColor: "#0B0B10",
    borderWidth: 1.5,
    borderColor: "rgba(255,255,255,0.12)",
    alignItems: "center",
    justifyContent: "center",
    ...shadow.md,
  },
  vinylGroove: {
    position: "absolute",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.06)",
  },
  vinylCenter: {
    position: "absolute",
    backgroundColor: accent.primary,
    alignItems: "center",
    justifyContent: "center",
  },
  spindle: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#000",
  },
  art: {
    borderRadius: radius.lg,
    overflow: "hidden",
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    justifyContent: "flex-end",
    ...shadow.sm,
  },
  qualityStripe: {
    position: "absolute",
    top: 10,
    left: 10,
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    backgroundColor: "rgba(0,0,0,0.55)",
    borderRadius: radius.xs,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.2)",
  },
  qualityStripeText: {
    color: "#fff",
    fontSize: 9,
    fontWeight: "900",
    letterSpacing: 0.8,
    fontFamily: font.sansBold,
  },
  folderIconBadge: {
    position: "absolute",
    bottom: 10,
    right: 10,
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: "rgba(15,23,42,0.85)",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.35)",
  },
  texts: { gap: 2, paddingHorizontal: 2 },
  title: {
    color: colors.text,
    fontSize: 13,
    fontWeight: "700",
    fontFamily: font.sansBold,
    letterSpacing: 0.1,
  },
  subtitle: {
    color: colors.textMuted,
    fontSize: 11,
    fontFamily: font.sansMedium,
  },
  countBadge: {
    alignSelf: "flex-start",
    marginTop: 2,
    backgroundColor: "rgba(255,255,255,0.06)",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  count: {
    color: colors.textDim,
    fontSize: 9,
    fontWeight: "800",
    fontFamily: font.mono,
    letterSpacing: 0.5,
  },
  artistRing: {
    borderWidth: 1.5,
    borderColor: "rgba(139,92,246,0.4)",
    alignItems: "center",
    justifyContent: "center",
    ...shadow.glow(accent.primary, 0.25),
  },
  artistArt: {
    overflow: "hidden",
    backgroundColor: "#161622",
  },
  artistTexts: {
    alignItems: "center",
    marginTop: 8,
    gap: 2,
    width: "100%",
  },
  artistName: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "800",
    fontFamily: font.sansBold,
    textAlign: "center",
  },
  artistCount: {
    color: colors.textMuted,
    fontSize: 9,
    fontWeight: "800",
    letterSpacing: 0.6,
    fontFamily: font.mono,
  },
});