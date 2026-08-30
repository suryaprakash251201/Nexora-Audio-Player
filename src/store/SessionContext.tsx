/**
 * Session provider.
 *
 * Mirrors the auth flow in the upstream `mobile/` app (POST /auth/login → {user,
 * token}, token stored in expo-secure-store with AsyncStorage fallback, Bearer
 * header on every request, auto sign-out on 401) while being typed for this
 * repo's API client and minimal UI.
 */
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import * as SecureStore from "expo-secure-store";
import AsyncStorage from "@react-native-async-storage/async-storage";
import type { User } from "@/api/types";
import { Api } from "@/api/client";

type SessionState = {
  booting: boolean;
  api: Api | null;
  user: User | null;
  baseUrl: string | null;
  token: string | null;
  login: (baseUrl: string, username: string, password: string, totpCode?: string) => Promise<{ ok: boolean; error?: string; totpRequired?: boolean; userId?: string }>;
  logout: () => Promise<void>;
  setBaseUrl: (url: string) => Promise<void>;
  setSession: (baseUrl: string, token: string, user: User) => Promise<void>;
};

const SessionContext = createContext<SessionState | null>(null);

const KEYS = {
  baseUrl: "nexora_audio.baseUrl",
  token: "nexora_audio.token",
  user: "nexora_audio.user",
} as const;

async function secureGet(key: string): Promise<string | null> {
  try {
    const v = await SecureStore.getItemAsync(key);
    if (v !== null) return v;
  } catch { /* ignore */ }
  try {
    return await AsyncStorage.getItem(key);
  } catch { return null; }
}

async function secureSet(key: string, value: string | null) {
  if (value === null) {
    try { await SecureStore.deleteItemAsync(key); } catch { /* ignore */ }
    try { await AsyncStorage.removeItem(key); } catch { /* ignore */ }
    return;
  }
  try {
    await SecureStore.setItemAsync(key, value);
    return;
  } catch { /* ignore */ }
  await AsyncStorage.setItem(key, value);
}

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [booting, setBooting] = useState(true);
  const [baseUrl, setBaseUrlState] = useState<string | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [api, setApi] = useState<Api | null>(null);

  // hydrate from storage
  useEffect(() => {
    (async () => {
      const [b, t, u] = await Promise.all([
        secureGet(KEYS.baseUrl),
        secureGet(KEYS.token),
        secureGet(KEYS.user),
      ]);
      let parsedUser: User | null = null;
      if (u) {
        try { parsedUser = JSON.parse(u) as User; } catch { parsedUser = null; }
      }
      setBaseUrlState(b);
      setToken(t);
      setUser(parsedUser);
      if (b && t) {
        const a = new Api(b, t);
        a.setUnauthorizedHandler(() => {
          // token expired — clear session; UI will navigate to login
          void (async () => {
            await Promise.all([secureSet(KEYS.token, null), secureSet(KEYS.user, null)]);
            setToken(null);
            setUser(null);
            setApi(null);
          })();
        });
        setApi(a);
      }
      setBooting(false);
    })();
  }, []);

  const persistSession = useCallback(async (nextBaseUrl: string, nextToken: string, nextUser: User) => {
    const a = new Api(nextBaseUrl, nextToken);
    a.setUnauthorizedHandler(() => {
      void (async () => {
        await Promise.all([secureSet(KEYS.token, null), secureSet(KEYS.user, null)]);
        setToken(null);
        setUser(null);
        setApi(null);
      })();
    });
    await Promise.all([
      secureSet(KEYS.baseUrl, nextBaseUrl),
      secureSet(KEYS.token, nextToken),
      secureSet(KEYS.user, JSON.stringify(nextUser)),
    ]);
    setBaseUrlState(nextBaseUrl);
    setToken(nextToken);
    setUser(nextUser);
    setApi(a);
  }, []);

  const setBaseUrl = useCallback(async (url: string) => {
    const trimmed = url.replace(/\/+$/, "");
    await secureSet(KEYS.baseUrl, trimmed);
    setBaseUrlState(trimmed);
    if (token && trimmed) {
      const a = new Api(trimmed, token);
      setApi(a);
    }
  }, [token]);

  const login = useCallback(async (
    nextBaseUrl: string,
    username: string,
    password: string,
    totpCode?: string,
  ): Promise<{ ok: boolean; error?: string; totpRequired?: boolean; userId?: string }> => {
    const trimmed = nextBaseUrl.replace(/\/+$/, "");
    const tmp = new Api(trimmed, null);
    try {
      if (totpCode) {
        const res = await tmp.verifyTotp(username, password, totpCode);
        await persistSession(trimmed, res.token, res.user);
        return { ok: true };
      }
      const res: any = await tmp.login(username, password);
      if (res?.totp_required) {
        // TOTP challenge — do not persist a session yet; return the challenge id
        // so the UI can show the code field.
        return { ok: false, totpRequired: true, userId: res.user_id };
      }
      if (res?.token && res?.user) {
        await persistSession(trimmed, res.token, res.user);
        return { ok: true };
      }
      // Cookie-only session (no token in body) — verify /auth/session gives a user
      const tmp2 = new Api(trimmed, null);
      // try to reuse cookie path — just attempt to fetch session; if we can't, ask
      // the caller to show an error.
      const sess = await tmp2.session().catch(() => null);
      if (sess?.user) {
        await persistSession(trimmed, "", sess.user);
        return { ok: true };
      }
      return { ok: false, error: res?.message || "Unexpected response from server." };
    } catch (e: any) {
      return { ok: false, error: e?.message || String(e) };
    }
  }, [persistSession]);

  const logout = useCallback(async () => {
    try { await api?.logout(); } catch { /* ignore */ }
    await Promise.all([secureSet(KEYS.token, null), secureSet(KEYS.user, null)]);
    setToken(null);
    setUser(null);
    setApi(null);
  }, [api]);

  const setSessionFn = useCallback(async (nextBaseUrl: string, nextToken: string, nextUser: User) => {
    await persistSession(nextBaseUrl, nextToken, nextUser);
  }, [persistSession]);

  const value = useMemo<SessionState>(() => ({
    booting, api, user, baseUrl, token,
    login, logout, setBaseUrl, setSession: setSessionFn,
  }), [booting, api, user, baseUrl, token, login, logout, setBaseUrl, setSessionFn]);

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): SessionState {
  const v = useContext(SessionContext);
  if (!v) throw new Error("useSession must be used within SessionProvider");
  return v;
}