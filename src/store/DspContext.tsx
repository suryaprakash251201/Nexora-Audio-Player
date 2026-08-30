/**
 * DSP context — 10-band EQ + preamp + balance + limiter + ReplayGain.
 * M1 stub. The real DSP abstraction (with platform modules) lands in M5.
 */
import React, { createContext, useContext, useMemo, useState } from "react";

export type DspPresetId = string;

export type EqState = {
  enabled: boolean;
  gainsDb: number[]; // length 10; -12..+12
  preampDb: number;  // -12..+12
  balance: number;   // -1..+1
  limiterEnabled: boolean;
  replayGainMode: "off" | "track" | "album";
  presetId: DspPresetId | null;
  setGains: (gains: number[]) => void;
  setPreamp: (v: number) => void;
  setBalance: (v: number) => void;
  setLimiterEnabled: (v: boolean) => void;
  setReplayGainMode: (m: EqState["replayGainMode"]) => void;
};

const DspContext = createContext<EqState | null>(null);

const DEFAULT_GAINS = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

export function DspProvider({ children }: { children: React.ReactNode }) {
  const [gainsDb, setGains] = useState<number[]>(DEFAULT_GAINS.slice());
  const [preampDb, setPreamp] = useState(0);
  const [balance, setBalance] = useState(0);
  const [limiterEnabled, setLimiterEnabled] = useState(false);
  const [replayGainMode, setReplayGainMode] = useState<EqState["replayGainMode"]>("off");

  const value = useMemo<EqState>(() => ({
    enabled: false,
    gainsDb, preampDb, balance, limiterEnabled, replayGainMode,
    presetId: null,
    setGains, setPreamp, setBalance, setLimiterEnabled, setReplayGainMode,
  }), [gainsDb, preampDb, balance, limiterEnabled, replayGainMode]);

  return <DspContext.Provider value={value}>{children}</DspContext.Provider>;
}

export function useDsp(): EqState {
  const v = useContext(DspContext);
  if (!v) throw new Error("useDsp must be used within DspProvider");
  return v;
}