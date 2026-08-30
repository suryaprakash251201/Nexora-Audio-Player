/**
 * DSP constants — 10-band graphic EQ bands + presets (M5).
 */

export const EQ_BANDS_HZ = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000] as const;
export const EQ_MIN_DB = -12;
export const EQ_MAX_DB = 12;
export const PREAMP_MIN_DB = -12;
export const PREAMP_MAX_DB = 12;
export const BALANCE_MIN = -1;
export const BALANCE_MAX = 1;

export type EqPreset = {
  id: string;
  name: string;
  gainsDb: number[]; // 10 values
  preampDb?: number;
  isBuiltIn?: boolean;
};

export const BUILT_IN_PRESETS: EqPreset[] = [
  { id: "flat", name: "Flat", gainsDb: [0,0,0,0,0,0,0,0,0,0], isBuiltIn: true },
  { id: "bass_boost", name: "Bass Boost", gainsDb: [5,4,3,1,0,0,0,0,0,0], preampDb: -1, isBuiltIn: true },
  { id: "treble_boost", name: "Treble Boost", gainsDb: [0,0,0,0,0,0,2,3,4,5], preampDb: -1, isBuiltIn: true },
  { id: "classical", name: "Classical", gainsDb: [0,0,0,0,0,0,-1,-2,-2,0], isBuiltIn: true },
  { id: "acoustic", name: "Acoustic", gainsDb: [2,1,0,1,1,0,1,2,1,0], isBuiltIn: true },
  { id: "jazz", name: "Jazz", gainsDb: [2,1,0,1,0,0,1,1,2,1], isBuiltIn: true },
  { id: "rock", name: "Rock", gainsDb: [3,2,1,0,-1,-1,0,1,2,3], isBuiltIn: true },
  { id: "pop", name: "Pop", gainsDb: [1,1,0,0,0,0,0,1,2,1], isBuiltIn: true },
  { id: "electronic", name: "Electronic", gainsDb: [3,2,0,0,-1,0,1,1,2,3], isBuiltIn: true },
  { id: "vocal", name: "Vocal", gainsDb: [-1,-1,0,1,3,3,2,0,-1,-1], isBuiltIn: true },
  { id: "audiophile", name: "Audiophile", gainsDb: [0,0,0,0,0,0,0,0,0,0], isBuiltIn: true },
  { id: "custom", name: "Custom", gainsDb: [0,0,0,0,0,0,0,0,0,0], isBuiltIn: false },
];

/**
 * Compute required headroom (negative preamp) to avoid clipping when any band
 * boosts above 0. Simple model: headroom = max boost.
 * Real limiter would do look-ahead; here we surface a recommendation.
 */
export function requiredHeadroomDb(gainsDb: number[]): number {
  const maxBoost = Math.max(0, ...gainsDb);
  return maxBoost;
}

export function clampGain(v: number): number {
  return Math.max(EQ_MIN_DB, Math.min(EQ_MAX_DB, v));
}
export function clampPreamp(v: number): number {
  return Math.max(PREAMP_MIN_DB, Math.min(PREAMP_MAX_DB, v));
}