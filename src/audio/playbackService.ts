/**
 * Headless playback service registered before the React tree mounts
 * (see `index.ts`). Receives remote-control events from the OS media session
 * (lock screen, Bluetooth, AirPods, headset buttons) and forwards them to the
 * player controller. Adapted from the upstream Nexora pattern.
 */
import { TrackPlayer, Event } from "./trackPlayerShim";

export const PlaybackService = async function () {
  // Defensive wrappers: iOS will kill the app if a remote handler throws.
  const safe = (fn: (...a: any[]) => any) => (...a: any[]) => {
    try { const r = fn(...a); if (r && typeof (r as any).catch === "function") (r as Promise<any>).catch((e) => console.warn("[PlaybackService] handler failed", e)); } catch (e) { console.warn("[PlaybackService] handler threw", e); }
  };
  TrackPlayer.addEventListener(Event.RemotePlay, safe(() => TrackPlayer.play()));
  TrackPlayer.addEventListener(Event.RemotePause, safe(() => TrackPlayer.pause()));
  TrackPlayer.addEventListener(Event.RemoteStop, safe(() => TrackPlayer.reset()));
  TrackPlayer.addEventListener(Event.RemoteSeek, safe(({ position }: any) => {
    if (typeof position === "number" && isFinite(position)) TrackPlayer.seekTo(position);
  }));
  TrackPlayer.addEventListener(Event.RemoteJumpForward, safe(({ interval }: any) => {
    TrackPlayer.seekBy(typeof interval === "number" ? interval : 15);
  }));
  TrackPlayer.addEventListener(Event.RemoteJumpBackward, safe(({ interval }: any) => {
    TrackPlayer.seekBy(-(typeof interval === "number" ? interval : 15));
  }));
  TrackPlayer.addEventListener(Event.RemoteDuck, safe(({ paused, permanent }: any) => {
    // On iOS, duck is for interruptions (phone call / Siri). Don't crash on missing permanent flag.
    if (paused || permanent) {
      TrackPlayer.pause();
    } else {
      TrackPlayer.pause();
      setTimeout(() => { void TrackPlayer.play().catch(() => {}); }, 800);
    }
  }));
  // iOS can also emit RemoteNext/Previous outside player.ts — keep no-ops here so they don't become unhandled.
  TrackPlayer.addEventListener((Event as any).RemoteNext, safe(() => TrackPlayer.play()));
  TrackPlayer.addEventListener((Event as any).RemotePrevious, safe(() => TrackPlayer.play()));
};