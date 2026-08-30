import React, { useState } from "react";
import { ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View, ScrollView, KeyboardAvoidingView, Platform } from "react-native";
import { Stack, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";

export default function LoginScreen() {
  const { login } = useSession();
  const [baseUrl, setBaseUrl] = useState("https://");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [totp, setTotp] = useState("");
  const [needsTotp, setNeedsTotp] = useState(false);
  const [pendingUserId, setPendingUserId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onSubmit = async () => {
    if (!baseUrl.trim() || !username.trim() || !password) {
      setError("Server URL, username and password are required.");
      return;
    }
    setBusy(true);
    setError(null);
    const res = await login(baseUrl.trim(), username.trim(), password, needsTotp ? totp : undefined);
    setBusy(false);
    if (res.ok) {
      router.replace("/(tabs)");
      return;
    }
    if (res.totpRequired) {
      setNeedsTotp(true);
      setPendingUserId(res.userId ?? null);
      setError("Two-factor code required.");
      return;
    }
    setError(res.error || "Login failed. Check server URL and credentials.");
  };

  return (
    <>
      <Stack.Screen options={{ presentation: "modal", headerShown: false }} />
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={{ flex: 1, backgroundColor: colors.bg }}>
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
          <Pressable onPress={() => router.back()} style={styles.close}>
            <Ionicons name="close" size={20} color={colors.textMuted} />
          </Pressable>

          <View style={styles.hero}>
            <View style={styles.logo}>
              <Ionicons name="musical-notes" size={28} color="#fff" />
            </View>
            <Text style={styles.title}>Connect to Nexora</Text>
            <Text style={styles.subtitle}>Enter your self-hosted server URL and sign in. Your session is stored securely on this device.</Text>
          </View>

          <View style={styles.form}>
            <Text style={styles.label}>Server URL</Text>
            <TextInput value={baseUrl} onChangeText={setBaseUrl} placeholder="https://nexora.example.com" placeholderTextColor={colors.textMuted} autoCapitalize="none" autoCorrect={false} keyboardType="url" style={styles.input} />
            <Text style={styles.hint}>Include https:// — local network URLs like http://192.168.1.50:8080 are allowed.</Text>

            <Text style={styles.label}>Username or email</Text>
            <TextInput value={username} onChangeText={setUsername} placeholder="you" placeholderTextColor={colors.textMuted} autoCapitalize="none" autoCorrect={false} style={styles.input} />

            <Text style={styles.label}>Password</Text>
            <TextInput value={password} onChangeText={setPassword} placeholder="••••••••" placeholderTextColor={colors.textMuted} secureTextEntry style={styles.input} />

            {needsTotp ? (
              <>
                <Text style={styles.label}>Authenticator code</Text>
                <TextInput value={totp} onChangeText={setTotp} placeholder="123 456" placeholderTextColor={colors.textMuted} keyboardType="number-pad" maxLength={6} style={styles.input} />
                {pendingUserId ? <Text style={styles.hint}>TOTP required for user {pendingUserId.slice(0, 8)}…</Text> : null}
              </>
            ) : null}

            {error ? <View style={styles.errorBox}><Text style={styles.errorText}>{error}</Text></View> : null}

            <Pressable onPress={onSubmit} disabled={busy} style={[styles.btn, busy && { opacity: 0.6 }]}>
              {busy ? <ActivityIndicator color="#fff" /> : <Text style={styles.btnLabel}>{needsTotp ? "Verify & sign in" : "Sign in"}</Text>}
            </Pressable>

            <Text style={styles.foot}>Nexora supports Tailscale MagicDNS and local-network discovery. If your server is on your LAN, use its LAN IP.</Text>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20, gap: 18, paddingTop: 28 },
  close: { alignSelf: "flex-end", width: 36, height: 36, borderRadius: 18, backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center" },
  hero: { alignItems: "center", gap: 10, paddingVertical: 12 },
  logo: { width: 56, height: 56, borderRadius: 14, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center" },
  title: { color: colors.text, fontSize: 22, fontWeight: "800" },
  subtitle: { color: colors.textMuted, fontSize: 13, textAlign: "center", lineHeight: 18, paddingHorizontal: 16 },
  form: { gap: 10, backgroundColor: colors.bgRaised, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: colors.hairline },
  label: { color: colors.textDim, fontSize: 11, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase", marginTop: 2 },
  input: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, borderRadius: 10, paddingHorizontal: 12, height: 42, color: colors.text, fontSize: 14 },
  hint: { color: colors.textMuted, fontSize: 11, lineHeight: 14 },
  errorBox: { backgroundColor: "rgba(248,113,113,0.12)", borderWidth: 1, borderColor: "rgba(248,113,113,0.22)", borderRadius: 10, padding: 10 },
  errorText: { color: "#FECACA", fontSize: 12, lineHeight: 16 },
  btn: { backgroundColor: colors.accent, height: 46, borderRadius: 11, alignItems: "center", justifyContent: "center", marginTop: 6 },
  btnLabel: { color: "#fff", fontWeight: "800", fontSize: 15 },
  foot: { color: colors.textMuted, fontSize: 11, lineHeight: 14, textAlign: "center", marginTop: 4 },
});