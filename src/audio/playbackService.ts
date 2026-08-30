/**
 * Headless playback service registered before the React tree mounts
 * (see `index.ts`). Receives remote-control events from the OS media session
 * (lock screen, Bluetooth, AirPods, headset buttons) and forwards them to the
 * player controller. Adapted from the upstream Nexora pattern.
 */
import { TrackPlayer, Event } from "./trackPlayerShim";

export const PlaybackService = async function () {
  TrackPlayer.addEventListener(Event.RemotePlay, () => TrackPlayer.play());
  TrackPlayer.addEventListener(Event.RemotePause, () => TrackPlayer.pause());
  TrackPlayer.addEventListener(Event.RemoteStop, () => TrackPlayer.reset());
  TrackPlayer.addEventListener(Event.RemoteSeek, ({ position }: any) => {
    TrackPlayer.seekTo(position);
  });
  TrackPlayer.addEventListener(Event.RemoteJumpForward, ({ interval }: any) => {
    TrackPlayer.seekBy(interval);
  });
  TrackPlayer.addEventListener(Event.RemoteJumpBackward, ({ interval }: any) => {
    TrackPlayer.seekBy(-interval);
  });
  TrackPlayer.addEventListener(Event.RemoteDuck, ({ paused }: any) => {
    TrackPlayer.pause();
    if (!paused) {
      // small grace period before resuming after a duck event
      setTimeout(() => TrackPlayer.play(), 800);
    }
  });
};