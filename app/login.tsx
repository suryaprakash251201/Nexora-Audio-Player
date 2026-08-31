import React, { useState, useEffect } from "react";
import { ActivityIndicator, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View, Switch } from "react-native";
import { Stack, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { colors, font, radius, spacing, accent, shadow } from "@/ui/theme";
import { useSession } from "@/store/SessionContext";
import { Toast } from "@/ui/Toast";
import { Haptics } from "@/lib/haptics";
import { Image } from "expo-image";

function normalizeUrl(input: string): string {
  let s = input.trim();
  if (!s) return "";
  if (!/^https?:\/\//i.test(s)) {
    // If user provided a raw host or IP like 192.168.1.5 or localhost:3000, default to http://
    s = `http://${s}`;
  }
  return s.replace(/\/+$/, "");
}

function isValidUrl(s: string): boolean {
  const norm = normalizeUrl(s);
  if (!norm) return false;
  return /^https?:\/\/[\w.-]+(?::\d+)?(\/.*)?$/i.test(norm);
}

export default function LoginScreen() {
  const { login } = useSession();
  const insets = useSafeAreaInsets();
  const [baseUrl, setBaseUrl] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [totp, setTotp] = useState("");
  const [needsTotp, setNeedsTotp] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPwd, setShowPwd] = useState(false);
  const [rememberUrl, setRememberUrl] = useState(true);

  useEffect(() => {
    AsyncStorage.getItem("nexora_remembered_server_url").then((url) => {
      if (url) {
        setBaseUrl(url);
        setRememberUrl(true);
      }
    });
  }, []);

  const onSubmit = async () => {
    const rawUrl = baseUrl.trim();
    if (!rawUrl) {
      setError("Server URL or IP address is required (e.g. 192.168.1.5 or http://192.168.1.5:3000)");
      return;
    }
    const normalizedUrl = normalizeUrl(rawUrl);
    if (!isValidUrl(normalizedUrl)) {
      setError("Please enter a valid server URL or IP address (e.g. 192.168.1.5 or http://192.168.1.5:3000)");
      return;
    }
    if (!username.trim()) {
      setError("Username or email is required");
      return;
    }
    if (!password) {
      setError("Password is required");
      return;
    }
    if (needsTotp && totp.length !== 6) {
      setError("Authenticator code must be 6 digits");
      return;
    }
    Haptics.tapLight();
    setBusy(true);
    setError(null);
    const res = await login(normalizedUrl, username.trim(), password, needsTotp ? totp : undefined);
    setBusy(false);
    if (res.ok) {
      if (rememberUrl) {
        await AsyncStorage.setItem("nexora_remembered_server_url", normalizedUrl);
      } else {
        await AsyncStorage.removeItem("nexora_remembered_server_url");
      }
      Toast.success("Connected to Nexora");
      Haptics.success();
      router.replace("/(tabs)");
      return;
    }
    if (res.totpRequired) {
      Haptics.selection();
      setNeedsTotp(true);
      setError("Two-factor authentication required.");
      return;
    }
    Haptics.error();
    
    // Improve error messages based on response
    let msg = res.error || "Server error. Please try again.";
    if (msg.includes("401") || msg.toLowerCase().includes("unauthorized") || msg.toLowerCase().includes("invalid username")) {
      msg = "Invalid username or password.";
    } else if (msg.includes("403")) {
      msg = "Access denied or 2FA required.";
    }
    setError(msg);
  };

  const currentNormalized = normalizeUrl(baseUrl);
  const isCurrentValid = isValidUrl(baseUrl);

  return (
    <>
      <Stack.Screen options={{ presentation: "modal", headerShown: false }} />
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={{ flex: 1, backgroundColor: colors.bg }}>
        <ScrollView
          contentContainerStyle={[styles.container, { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 20 }]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.topBar}>
            <Pressable
              onPress={() => {
                Haptics.tapLight();
                router.back();
              }}
              hitSlop={10}
              style={styles.closeBtn}
              accessibilityLabel="Close"
            >
              <Ionicons name="close" size={20} color={colors.textDim} />
            </Pressable>
          </View>

          <View style={styles.hero}>
            <View style={styles.logoRing}>
              <Image
                source={require("../assets/icon.png")}
                style={styles.logoImage}
                contentFit="cover"
              />
            </View>
            <Text style={styles.title}>Connect to Nexora</Text>
            <Text style={styles.subtitle}>
              Sign into your self-hosted high-resolution audio library. Credentials are encrypted in the hardware secure enclave.
            </Text>
          </View>

          <View style={styles.form}>
            <Text style={styles.label}>Server URL or IP</Text>
            <View style={styles.inputRow}>
              {currentNormalized.startsWith("https://") ? (
                <Ionicons name="lock-closed" size={16} color="#10B981" style={{ marginRight: 6 }} />
              ) : currentNormalized.startsWith("http://") ? (
                <Ionicons name="globe-outline" size={16} color="#06B6D4" style={{ marginRight: 6 }} />
              ) : null}
              <TextInput
                value={baseUrl}
                onChangeText={(t) => {
                  setBaseUrl(t);
                  if (error) setError(null);
                }}
                placeholder="192.168.1.5 or https://nexora.example.com"
                placeholderTextColor={colors.textMuted}
                autoCapitalize="none"
                autoCorrect={false}
                keyboardType="url"
                autoComplete="url"
                textContentType="URL"
                style={[styles.input, { flex: 1, borderWidth: 0, paddingHorizontal: 0, backgroundColor: "transparent" }]}
              />
              {baseUrl.trim().length > 0 && (
                <Ionicons
                  name={isCurrentValid ? "checkmark-circle" : "close-circle"}
                  size={18}
                  color={isCurrentValid ? "#10B981" : "#F87171"}
                />
              )}
            </View>
            <Text style={styles.hint}>LAN IPs like 192.168.1.5 (or with port e.g. 192.168.1.5:3000) and HTTPS domains are supported.</Text>
            
            <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginTop: 4, marginBottom: 8 }}>
              <Text style={styles.hint}>Remember server URL</Text>
              <Switch
                value={rememberUrl}
                onValueChange={setRememberUrl}
                trackColor={{ false: "rgba(255,255,255,0.1)", true: accent.primary }}
                thumbColor={Platform.OS === "android" ? "#fff" : undefined}
                ios_backgroundColor="rgba(255,255,255,0.1)"
              />
            </View>

            <Text style={styles.label}>Username or Email</Text>
            <TextInput
              value={username}
              onChangeText={(t) => {
                setUsername(t);
                if (error) setError(null);
              }}
              placeholder="username"
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
                onChangeText={(t) => {
                  setPassword(t);
                  if (error) setError(null);
                }}
                placeholder="••••••••"
                placeholderTextColor={colors.textMuted}
                secureTextEntry={!showPwd}
                autoComplete="password"
                textContentType="password"
                style={[styles.input, { flex: 1, borderWidth: 0, paddingHorizontal: 0, backgroundColor: "transparent" }]}
              />
              <Pressable onPress={() => setShowPwd((v) => !v)} hitSlop={10} style={{ paddingHorizontal: 8 }}>
                <Ionicons name={showPwd ? "eye-off" : "eye"} size={18} color={colors.textMuted} />
              </Pressable>
            </View>

            {needsTotp ? (
              <>
                <Text style={styles.label}>Authenticator 2FA Code</Text>
                <TextInput
                  value={totp}
                  onChangeText={(t) => setTotp(t.replace(/\D/g, "").slice(0, 6))}
                  placeholder="123 456"
                  placeholderTextColor={colors.textMuted}
                  keyboardType="number-pad"
                  maxLength={6}
                  style={[styles.input, { letterSpacing: 8, textAlign: "center", fontFamily: font.monoBold }]}
                />
              </>
            ) : null}

            {error ? (
              <View style={styles.errorBox}>
                <Ionicons name="alert-circle" size={16} color="#F87171" />
                <Text style={styles.errorText}>{error}</Text>
              </View>
            ) : null}

            <Pressable
              onPress={onSubmit}
              disabled={busy}
              style={({ pressed }) => [styles.btn, busy && { opacity: 0.7 }, pressed && { opacity: 0.85 }]}
              accessibilityLabel="Sign in"
            >
              {busy ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <>
                  <Ionicons name={needsTotp ? "shield-checkmark" : "log-in"} size={18} color="#fff" />
                  <Text style={styles.btnLabel}>{needsTotp ? "Verify & Connect" : "Connect to Server"}</Text>
                </>
              )}
            </Pressable>

            <Text style={styles.foot}>
              Nexora supports Tailscale MagicDNS and local WiFi streaming.
            </Text>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </>
  );
}

const styles = StyleSheet.create({
  container: { paddingHorizontal: spacing.lg, gap: spacing.lg },
  topBar: { flexDirection: "row", alignItems: "center", minHeight: 36 },
  closeBtn: {
    width: 38,
    height: 38,
    borderRadius: radius.md,
    backgroundColor: colors.card,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
  },
  hero: { alignItems: "center", gap: 10, paddingVertical: 12 },
  logoRing: {
    width: 80,
    height: 80,
    borderRadius: 22,
    borderWidth: 1.5,
    borderColor: "rgba(139,92,246,0.45)",
    overflow: "hidden",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#0B0B12",
    ...shadow.glow(accent.primary, 0.4),
  },
  logoImage: {
    width: 80,
    height: 80,
  },
  title: {
    color: colors.text,
    fontSize: 24,
    fontWeight: "900",
    fontFamily: font.sansBold,
    letterSpacing: -0.4,
  },
  subtitle: {
    color: colors.textMuted,
    fontSize: 13,
    textAlign: "center",
    lineHeight: 18,
    paddingHorizontal: 12,
    fontFamily: font.sansRegular,
  },
  form: {
    gap: 10,
    backgroundColor: colors.card,
    borderRadius: radius.xl,
    padding: spacing.lg,
    borderWidth: 1,
    borderColor: colors.hairlineStrong,
    ...shadow.sm,
  },
  label: {
    color: colors.textDim,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 1.0,
    textTransform: "uppercase",
    fontFamily: font.sansBold,
    marginTop: 4,
  },
  input: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    borderRadius: radius.md,
    paddingHorizontal: 14,
    height: 48,
    color: colors.text,
    fontSize: 14,
    fontFamily: font.sansMedium,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: 1,
    borderColor: colors.hairline,
    borderRadius: radius.md,
    paddingHorizontal: 14,
    height: 48,
  },
  hint: {
    color: colors.textMuted,
    fontSize: 11,
    lineHeight: 15,
    fontFamily: font.sansRegular,
  },
  errorBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    backgroundColor: "rgba(239,68,68,0.14)",
    borderWidth: 1,
    borderColor: "rgba(239,68,68,0.3)",
    borderRadius: radius.md,
    padding: 12,
    marginTop: 6,
  },
  errorText: {
    color: "#FECACA",
    fontSize: 12,
    lineHeight: 16,
    fontFamily: font.sansMedium,
    flex: 1,
  },
  btn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    backgroundColor: accent.primary,
    height: 50,
    borderRadius: radius.md,
    marginTop: 8,
    ...shadow.glow(accent.primary, 0.4),
  },
  btnLabel: {
    color: "#fff",
    fontWeight: "900",
    fontSize: 15,
    fontFamily: font.sansBold,
  },
  foot: {
    color: colors.textMuted,
    fontSize: 11,
    lineHeight: 16,
    textAlign: "center",
    marginTop: 6,
    fontFamily: font.sansRegular,
  },
});