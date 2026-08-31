/**
 * Native shim for react-native-track-player.
 *
 * Web uses `trackPlayerShim.web.ts` (Metro `.web` extension) so the native
 * module + `shaka-player` peer are never bundled for web. This file is only
 * evaluated on iOS/Android. It tries to require the native module and falls
 * back to a no-op stub if the package is missing (e.g. in Jest).
 */
let mod: any = null;
let loadFailed = false;

try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  mod = require("react-native-track-player");
} catch {
  mod = null;
  loadFailed = true;
}

const stub = {
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
};

export const TrackPlayer: any = loadFailed ? stub : mod.default ?? mod;

export const AppKilledPlaybackBehavior: any = loadFailed
  ? { ContinuePlayback: 0, StopPlaybackAndRemoveNotification: 1, PausePlayback: 2 }
  : mod.AppKilledPlaybackBehavior;

export const Capability: any = loadFailed
  ? {
      Play: "play",
      Pause: "pause",
      SkipToNext: "next",
      SkipToPrevious: "previous",
      SeekTo: "seek",
      Stop: "stop",
      JumpForward: "jumpForward",
      JumpBackward: "jumpBackward",
    }
  : mod.Capability;

export const Event: any = loadFailed
  ? {
      PlaybackState: "playback-state",
      PlaybackActiveTrackChanged: "playback-active-track-changed",
      PlaybackQueueEnded: "playback-queue-ended",
      PlaybackError: "playback-error",
      RemoteNext: "remote-next",
      RemotePrevious: "remote-previous",
      RemotePlay: "remote-play",
      RemotePause: "remote-pause",
      RemoteStop: "remote-stop",
      RemoteSeek: "remote-seek",
      RemoteJumpForward: "remote-jump-forward",
      RemoteJumpBackward: "remote-jump-backward",
      RemoteDuck: "remote-duck",
    }
  : mod.Event;

export const RepeatMode: any = loadFailed ? { Off: 0, Track: 1, Queue: 2 } : mod.RepeatMode;
export const State: any = loadFailed
  ? { None: 0, Ready: 1, Playing: 2, Paused: 3, Stopped: 4, Buffering: 5, Connecting: 6, Error: 7 }
  : mod.State;