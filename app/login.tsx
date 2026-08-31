import React, { useState } from "react";
import { ActivityIndicator, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { Stack, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { colors, font, radius, spacing } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { Toast } from "@/ui/Toast";
import { Haptics } from "@/lib/haptics";

function isValidUrl(s: string): boolean {
  const t = s.trim();
  if (!t) return false;
  return /^https?:\/\/[\w.-]+(?::\d+)?(\/.*)?$/i.test(t);
}

export default function LoginScreen() {
  const { login } = useSession();
  const insets = useSafeAreaInsets();
  const [baseUrl, setBaseUrl] = useState("https://");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [totp, setTotp] = useState("");
  const [needsTotp, setNeedsTotp] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPwd, setShowPwd] = useState(false);

  const onSubmit = async () => {
    if (!isValidUrl(baseUrl)) { setError("Server URL must start with http:// or https://"); return; }
    if (!username.trim()) { setError("Username or email is required"); return; }
    if (!password) { setError("Password is required"); return; }
    if (needsTotp && totp.length !== 6) { setError("Authenticator code must be 6 digits"); return; }
    Haptics.tapLight();
    setBusy(true); setError(null);
    const res = await login(baseUrl.trim(), username.trim(), password, needsTotp ? totp : undefined);
    setBusy(false);
    if (res.ok) {
      Toast.success("Connected to Nexora");
      Haptics.success();
      router.replace("/(tabs)");
      return;
    }
    if (res.totpRequired) {
      Haptics.selection();
      setNeedsTotp(true);
      setError("Two-factor code required");
      return;
    }
    Haptics.error();
    setError(res.error || "Login failed. Check server URL and credentials.");
  };

  return (
    <>
      <Stack.Screen options={{ presentation: "modal", headerShown: false }} />
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={{ flex: 1, backgroundColor: colors.bg }}>
        <ScrollView
          contentContainerStyle={[styles.container, { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 20 }]}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.topBar}>
            <Pressable onPress={() => { Haptics.tapLight(); router.back(); }} hitSlop={10} style={styles.closeBtn} accessibilityLabel="Close">
              <Ionicons name="close" size={20} color={colors.textMuted} />
            </Pressable>
            <View style={{ flex: 1 }} />
          </View>

          <View style={styles.hero}>
            <View style={styles.logo}>
              <Ionicons name="headset" size={28} color="#fff" />
            </View>
            <Text style={styles.title}>Connect to Nexora</Text>
            <Text style={styles.subtitle}>Enter your self-hosted server URL and sign in. Your session is stored in the device secure enclave.</Text>
          </View>

          <View style={styles.form}>
            <Text style={styles.label}>Server URL</Text>
            <TextInput
              value={baseUrl}
              onChangeText={(t) => { setBaseUrl(t); if (error) setError(null); }}
              placeholder="https://nexora.example.com"
              placeholderTextColor={colors.textMuted}
              autoCapitalize="none"
              autoCorrect={false}
              keyboardType="url"
              autoComplete="url"
              textContentType="URL"
              style={styles.input}
            />
            <Text style={styles.hint}>Include https:// — LAN URLs like http://192.168.1.50:8080 work too.</Text>

            <Text style={styles.label}>Username or email</Text>
            <TextInput
              value={username}
              onChangeText={(t) => { setUsername(t); if (error) setError(null); }}
              placeholder="you"
              placeholderTextColor={colors.textMuted}
              autoCapitalize="none"
              autoCorrect={false}
              autoComplete="username"
              textContentType="username"
              style={styles.input}
            />

            <Text style={styles.label}>Password</Text>
            <View style={styles.inputRow}>
              <TextInput
                value={password}
                onChangeText={(t) => { setPassword(t); if (error) setError(null); }}
                placeholder="••••••••"
                placeholderTextColor={colors.textMuted}
                secureTextEntry={!showPwd}
                autoComplete="password"
                textContentType="password"
                style={[styles.input, { flex: 1, borderWidth: 0, paddingHorizontal: 0, backgroundColor: "transparent" }]}
              />
              <Pressable onPress={() => setShowPwd((v) => !v)} hitSlop={10} style={{ paddingHorizontal: 6 }}>
                <Ionicons name={showPwd ? "eye-off" : "eye"} size={18} color={colors.textMuted} />
              </Pressable>
            </View>

            {needsTotp ? (
              <>
                <Text style={styles.label}>Authenticator code</Text>
                <TextInput
                  value={totp}
                  onChangeText={(t) => setTotp(t.replace(/\D/g, "").slice(0, 6))}
                  placeholder="123 456"
                  placeholderTextColor={colors.textMuted}
                  keyboardType="number-pad"
                  maxLength={6}
                  style={[styles.input, { letterSpacing: 8, textAlign: "center" }]}
                />
              </>
            ) : null}

            {error ? (
              <View style={styles.errorBox}>
                <Ionicons name="alert-circle" size={14} color="#FCA5A5" />
                <Text style={styles.errorText}>{error}</Text>
              </View>
            ) : null}

            <Pressable onPress={onSubmit} disabled={busy} style={[styles.btn, busy && { opacity: 0.7 }]} accessibilityLabel="Sign in">
              {busy ? <ActivityIndicator color="#fff" /> : (
                <>
                  <Ionicons name={needsTotp ? "shield-checkmark" : "log-in"} size={16} color="#fff" />
                  <Text style={styles.btnLabel}>{needsTotp ? "Verify & sign in" : "Sign in"}</Text>
                </>
              )}
            </Pressable>

            <Text style={styles.foot}>Nexora supports Tailscale MagicDNS and local-network discovery. Use your LAN IP if your server is on Wi-Fi.</Text>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </>
  );
}

const styles = StyleSheet.create({
  container: { paddingHorizontal: spacing.lg, gap: spacing.lg },
  topBar: { flexDirection: "row", alignItems: "center", minHeight: 36 },
  closeBtn: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.card, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.hairline },
  hero: { alignItems: "center", gap: 10, paddingVertical: 12 },
  logo: { width: 64, height: 64, borderRadius: 18, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", shadowColor: colors.accent, shadowOpacity: 0.45, shadowRadius: 16, shadowOffset: { width: 0, height: 6 }, elevation: 8 },
  title: { color: colors.text, fontSize: 24, fontWeight: "800", fontFamily: font.sansBold, letterSpacing: -0.4 },
  subtitle: { color: colors.textMuted, fontSize: 13, textAlign: "center", lineHeight: 18, paddingHorizontal: 12, fontFamily: font.sansRegular },
  form: { gap: 10, backgroundColor: colors.card, borderRadius: radius.lg, padding: spacing.lg, borderWidth: 1, borderColor: colors.hairline },
  label: { color: colors.textDim, fontSize: 10, fontWeight: "800", letterSpacing: 0.6, textTransform: "uppercase", fontFamily: font.sansBold, marginTop: 4 },
  input: { backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, paddingHorizontal: 12, height: 46, color: colors.text, fontSize: 14, fontFamily: font.sansRegular },
  inputRow: { flexDirection: "row", alignItems: "center", backgroundColor: "rgba(255,255,255,0.06)", borderWidth: 1, borderColor: colors.hairline, borderRadius: 12, paddingHorizontal: 12, height: 46 },
  hint: { color: colors.textMuted, fontSize: 11, lineHeight: 14, fontFamily: font.sansRegular },
  errorBox: { flexDirection: "row", alignItems: "flex-start", gap: 8, backgroundColor: "rgba(248,113,113,0.14)", borderWidth: 1, borderColor: "rgba(248,113,113,0.32)", borderRadius: 10, padding: 10, marginTop: 6 },
  errorText: { color: "#FECACA", fontSize: 12, lineHeight: 16, fontFamily: font.sansMedium, flex: 1 },
  btn: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, backgroundColor: colors.accent, height: 50, borderRadius: 14, marginTop: 6, shadowColor: colors.accent, shadowOpacity: 0.35, shadowRadius: 12, shadowOffset: { width: 0, height: 6 }, elevation: 8 },
  btnLabel: { color: "#fff", fontWeight: "800", fontSize: 15, fontFamily: font.sansBold },
  foot: { color: colors.textMuted, fontSize: 11, lineHeight: 16, textAlign: "center", marginTop: 6, fontFamily: font.sansRegular },
});