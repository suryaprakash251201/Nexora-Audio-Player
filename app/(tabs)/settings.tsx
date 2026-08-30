import React from "react";
import { Alert, Pressable, StyleSheet, Text, View, ScrollView } from "react-native";
import { colors } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function SettingsScreen() {
  const { api, user, baseUrl, logout } = useSession();

  const onLogout = () => {
    Alert.alert("Sign out?", "You will be asked to connect again.", [
      { text: "Cancel", style: "cancel" },
      { text: "Sign out", style: "destructive", onPress: () => void logout() },
    ]);
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.bg }} contentContainerStyle={{ padding: 16, gap: 16 }}>
      <Text style={styles.title}>Settings</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Server</Text>
        <Text style={styles.cardBody}>{baseUrl ?? "Not connected"}</Text>
        <Text style={styles.cardHint}>{user ? `Signed in as ${user.username} (${user.role})` : "Not signed in"}</Text>
        <View style={{ flexDirection: "row", gap: 10, marginTop: 8 }}>
          <Pressable onPress={() => router.push("/login")} style={styles.btn}>
            <Text style={styles.btnLabel}>{api ? "Change server" : "Connect"}</Text>
          </Pressable>
          {api ? (
            <Pressable onPress={onLogout} style={[styles.btn, { backgroundColor: "rgba(248,113,113,0.14)", borderWidth: 1, borderColor: "rgba(248,113,113,0.22)" }]}>
              <Text style={[styles.btnLabel, { color: "#FCA5A5" }]}>Sign out</Text>
            </Pressable>
          ) : null}
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Audio</Text>
        <Text style={styles.cardBody}>Quality detection, DSP and analyzer land in M5–M6. Playback already uses the server's smart transcode router so lossless sources stay lossless where supported.</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>About</Text>
        <Text style={styles.cardBody}>Nexora Audiophile — M2 unified library. Build with Expo 54, RN 0.81, TrackPlayer 4.1.2. See docs/ARCHITECTURE.md and docs/ROADMAP.md.</Text>
        <Pressable onPress={() => router.push("/dsp")} style={[styles.btn, { marginTop: 8, backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline }]}>
          <Ionicons name="options-outline" size={14} color={colors.text} />
          <Text style={[styles.btnLabel, { color: colors.text }]}>  Studio DSP (M5)</Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  title: { color: colors.text, fontSize: 20, fontWeight: "800" },
  card: { backgroundColor: colors.bgRaised, borderWidth: 1, borderColor: colors.hairline, borderRadius: 14, padding: 14, gap: 6 },
  cardTitle: { color: colors.text, fontWeight: "800", fontSize: 13 },
  cardBody: { color: colors.textDim, fontSize: 12, lineHeight: 16 },
  cardHint: { color: colors.textMuted, fontSize: 11 },
  btn: { flexDirection: "row", alignItems: "center", justifyContent: "center", backgroundColor: colors.accent, paddingHorizontal: 14, paddingVertical: 9, borderRadius: 10 },
  btnLabel: { color: "#fff", fontWeight: "800", fontSize: 12 },
});