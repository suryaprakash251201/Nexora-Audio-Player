/**
 * DSP context — 10-band EQ + preamp + balance + limiter + ReplayGain (M5).
 *
 * Platform-specific audio processing (AudioUnitEQ vs android.media.audiofx)
 * will be bridged in the native modules `src/dsp/native/` when M5's native
 * layer lands. For M5/M7 the context stores state durably in SQLite `dsp_state`
 * and exposes a `requiredHeadroom` helper so the UI warns about clipping
 * before the native chain is connected (brief: "prevent clipping").
 */
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { openDb } from "@/storage/db";
import { BUILT_IN_PRESETS, EQ_BANDS_HZ, requiredHeadroomDb, clampGain, clampPreamp } from "@/dsp/constants";

export type DspPresetId = string;

export type EqState = {
  enabled: boolean;
  gainsDb: number[]; // length 10
  preampDb: number;
  balance: number; // -1..1
  crossfeed: number; // 0..1
  stereoWidth: number; // 0.5..1.5
  limiterEnabled: boolean;
  replayGainMode: "off" | "track" | "album";
  presetId: DspPresetId | null;
  requiredHeadroomDb: number;
  setEnabled: (v: boolean) => void;
  setGains: (gains: number[]) => void;
  setGainAt: (index: number, db: number) => void;
  setPreamp: (v: number) => void;
  setBalance: (v: number) => void;
  setCrossfeed: (v: number) => void;
  setStereoWidth: (v: number) => void;
  setLimiterEnabled: (v: boolean) => void;
  setReplayGainMode: (m: EqState["replayGainMode"]) => void;
  applyPreset: (id: string) => void;
  reset: () => void;
};

const DspContext = createContext<EqState | null>(null);
const DEFAULT_GAINS = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
const STORAGE_KEYS = {
  enabled: "dsp.enabled",
  gains: "dsp.gains",
  preamp: "dsp.preamp",
  balance: "dsp.balance",
  crossfeed: "dsp.crossfeed",
  width: "dsp.width",
  limiter: "dsp.limiter",
  replayGain: "dsp.replayGain",
  preset: "dsp.preset",
} as const;

async function loadStored<K extends string>(key: string, fallback: string): Promise<string> {
  try {
    const db = await openDb();
    const row = await db.getFirstAsync<{ value: string }>(`SELECT value FROM dsp_state WHERE key = ?`, key);
    return row?.value ?? fallback;
  } catch { return fallback; }
}
async function saveStored(key: string, value: string) {
  try {
    const db = await openDb();
    await db.runAsync(`INSERT INTO dsp_state (key, value, updated_at) VALUES (?, ?, datetime('now')) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = datetime('now')`, key, value);
  } catch { /* ignore */ }
}

export function DspProvider({ children }: { children: React.ReactNode }) {
  const [enabled, setEnabled] = useState(false);
  const [gainsDb, setGains] = useState<number[]>(DEFAULT_GAINS.slice());
  const [preampDb, setPreamp] = useState(0);
  const [balance, setBalance] = useState(0);
  const [crossfeed, setCrossfeed] = useState(0);
  const [stereoWidth, setStereoWidth] = useState(1);
  const [limiterEnabled, setLimiterEnabled] = useState(false);
  const [replayGainMode, setReplayGainMode] = useState<EqState["replayGainMode"]>("off");
  const [presetId, setPresetId] = useState<string | null>(null);

  // hydrate
  useEffect(() => {
    (async () => {
      const [en, gains, pre, bal, cf, w, lim, rg, preset] = await Promise.all([
        loadStored(STORAGE_KEYS.enabled, "0"),
        loadStored(STORAGE_KEYS.gains, JSON.stringify(DEFAULT_GAINS)),
        loadStored(STORAGE_KEYS.preamp, "0"),
        loadStored(STORAGE_KEYS.balance, "0"),
        loadStored(STORAGE_KEYS.crossfeed, "0"),
        loadStored(STORAGE_KEYS.width, "1"),
        loadStored(STORAGE_KEYS.limiter, "0"),
        loadStored(STORAGE_KEYS.replayGain, "off"),
        loadStored(STORAGE_KEYS.preset, ""),
      ]);
      setEnabled(en === "1");
      try { const g = JSON.parse(gains); if (Array.isArray(g) && g.length === 10) setGains(g.map(clampGain)); } catch {}
      setPreamp(clampPreamp(parseFloat(pre) || 0));
      setBalance(Math.max(-1, Math.min(1, parseFloat(bal) || 0)));
      setCrossfeed(Math.max(0, Math.min(1, parseFloat(cf) || 0)));
      setStereoWidth(Math.max(0.5, Math.min(1.5, parseFloat(w) || 1)));
      setLimiterEnabled(lim === "1");
      if (rg === "track" || rg === "album" || rg === "off") setReplayGainMode(rg);
      setPresetId(preset || null);
    })();
  }, []);

  const persist = useCallback((key: string, val: string) => { void saveStored(key, val); }, []);

  const setEnabledWrap = useCallback((v: boolean) => { setEnabled(v); persist(STORAGE_KEYS.enabled, v ? "1" : "0"); }, [persist]);
  const setGainsWrap = useCallback((gains: number[]) => {
    const clamped = gains.map(clampGain);
    setGains(clamped);
    setPresetId(null);
    persist(STORAGE_KEYS.gains, JSON.stringify(clamped));
    persist(STORAGE_KEYS.preset, "");
  }, [persist]);
  const setGainAt = useCallback((idx: number, db: number) => {
    setGains((prev) => {
      const next = [...prev];
      next[idx] = clampGain(db);
      persist(STORAGE_KEYS.gains, JSON.stringify(next));
      persist(STORAGE_KEYS.preset, "");
      return next;
    });
    setPresetId(null);
  }, [persist]);
  const setPreampWrap = useCallback((v: number) => { const c = clampPreamp(v); setPreamp(c); persist(STORAGE_KEYS.preamp, String(c)); }, [persist]);
  const setBalanceWrap = useCallback((v: number) => { const c = Math.max(-1, Math.min(1, v)); setBalance(c); persist(STORAGE_KEYS.balance, String(c)); }, [persist]);
  const setCrossfeedWrap = useCallback((v: number) => { const c = Math.max(0, Math.min(1, v)); setCrossfeed(c); persist(STORAGE_KEYS.crossfeed, String(c)); }, [persist]);
  const setStereoWidthWrap = useCallback((v: number) => { const c = Math.max(0.5, Math.min(1.5, v)); setStereoWidth(c); persist(STORAGE_KEYS.width, String(c)); }, [persist]);
  const setLimiterWrap = useCallback((v: boolean) => { setLimiterEnabled(v); persist(STORAGE_KEYS.limiter, v ? "1" : "0"); }, [persist]);
  const setReplayGainWrap = useCallback((m: EqState["replayGainMode"]) => { setReplayGainMode(m); persist(STORAGE_KEYS.replayGain, m); }, [persist]);

  const applyPreset = useCallback((id: string) => {
    const preset = BUILT_IN_PRESETS.find((p) => p.id === id);
    if (!preset) return;
    setGains(preset.gainsDb.slice());
    if (typeof preset.preampDb === "number") setPreamp(preset.preampDb);
    setPresetId(id);
    persist(STORAGE_KEYS.gains, JSON.stringify(preset.gainsDb));
    persist(STORAGE_KEYS.preset, id);
  }, [persist]);

  const reset = useCallback(() => {
    setGains(DEFAULT_GAINS.slice());
    setPreamp(0);
    setBalance(0);
    setCrossfeed(0);
    setStereoWidth(1);
    setLimiterEnabled(false);
    setReplayGainMode("off");
    setPresetId("flat");
    persist(STORAGE_KEYS.gains, JSON.stringify(DEFAULT_GAINS));
    persist(STORAGE_KEYS.preamp, "0");
    persist(STORAGE_KEYS.balance, "0");
    persist(STORAGE_KEYS.crossfeed, "0");
    persist(STORAGE_KEYS.width, "1");
    persist(STORAGE_KEYS.limiter, "0");
    persist(STORAGE_KEYS.replayGain, "off");
    persist(STORAGE_KEYS.preset, "flat");
  }, [persist]);

  const requiredHeadroom = useMemo(() => requiredHeadroomDb(gainsDb), [gainsDb]);

  const value = useMemo<EqState>(() => ({
    enabled, gainsDb, preampDb, balance, crossfeed, stereoWidth, limiterEnabled, replayGainMode,
    presetId, requiredHeadroomDb: requiredHeadroom,
    setEnabled: setEnabledWrap, setGains: setGainsWrap, setGainAt, setPreamp: setPreampWrap, setBalance: setBalanceWrap,
    setCrossfeed: setCrossfeedWrap, setStereoWidth: setStereoWidthWrap, setLimiterEnabled: setLimiterWrap, setReplayGainMode: setReplayGainWrap,
    applyPreset, reset,
  }), [enabled, gainsDb, preampDb, balance, crossfeed, stereoWidth, limiterEnabled, replayGainMode, presetId, requiredHeadroom, setEnabledWrap, setGainsWrap, setGainAt, setPreampWrap, setBalanceWrap, setCrossfeedWrap, setStereoWidthWrap, setLimiterWrap, setReplayGainWrap, applyPreset, reset]);

  return <DspContext.Provider value={value}>{children}</DspContext.Provider>;
}

export function useDsp(): EqState {
  const v = useContext(DspContext);
  if (!v) throw new Error("useDsp must be used within DspProvider");
  return v;
}

export const EQ_BAND_LABELS = EQ_BANDS_HZ.map((hz) => hz >= 1000 ? `${hz / 1000}k` : `${hz}`);