/**
 * Web-safe shim for react-native-track-player.
 *
 * On web, TrackPlayer doesn't exist (no native queue). We expose a no-op
 * stub with the same surface so the web bundle can compile and the Playback
 * context degrades gracefully (queue state still works, but actual playback
 * on web falls back to HTML5 — wired in M7).
 *
 * On native, re-export the real module.
 */
import { Platform } from "react-native";

let mod: any = null;
let isWeb = Platform.OS === "web";

if (!isWeb) {
  try {
    mod = require("react-native-track-player");
  } catch {
    mod = null;
    isWeb = true;
  }
}

export const TrackPlayer: any = isWeb
  ? {
      setupPlayer: async () => {},
      updateOptions: async () => {},
      addEventListener: () => ({ remove: () => {} }),
      getProgress: async () => ({ position: 0, duration: 0, buffered: 0 }),
      play: async () => {},
      pause: async () => {},
      seekBy: async () => {},
      seekTo: async () => {},
      reset: async () => {},
      setRepeatMode: async () => {},
      setVolume: async () => {},
      add: async () => {},
      skip: async () => {},
      remove: async () => {},
      registerPlaybackService: () => {},
    }
  : mod.default ?? mod;

export const AppKilledPlaybackBehavior: any = isWeb
  ? { ContinuePlayback: 0, StopPlaybackAndRemoveNotification: 1, PausePlayback: 2 }
  : mod.AppKilledPlaybackBehavior;

export const Capability: any = isWeb
  ? {
      Play: "play", Pause: "pause", SkipToNext: "next", SkipToPrevious: "previous",
      SeekTo: "seek", Stop: "stop", JumpForward: "jumpForward", JumpBackward: "jumpBackward",
    }
  : mod.Capability;

export const Event: any = isWeb
  ? {
      PlaybackState: "playback-state",
      PlaybackActiveTrackChanged: "playback-active-track-changed",
      PlaybackQueueEnded: "playback-queue-ended",
      PlaybackError: "playback-error",
      RemoteNext: "remote-next",
      RemotePrevious: "remote-previous",
    }
  : mod.Event;

export const RepeatMode: any = isWeb ? { Off: 0, Track: 1, Queue: 2 } : mod.RepeatMode;
export const State: any = isWeb
  ? { None: 0, Ready: 1, Playing: 2, Paused: 3, Stopped: 4, Buffering: 5, Connecting: 6, Error: 7 }
  : mod.State;