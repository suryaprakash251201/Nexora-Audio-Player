/**
 * Web stub for react-native-track-player — never imports the native module.
 * Metro picks this file for `platform === "web"` via the `.web.ts` extension,
 * so `react-native-track-player` (and its `shaka-player` peer) is tree-shaken
 * out of the web bundle. Mirrors `trackPlayerShim.ts` surface.
 */

export const TrackPlayer: any = {
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

export const AppKilledPlaybackBehavior: any = {
  ContinuePlayback: 0,
  StopPlaybackAndRemoveNotification: 1,
  PausePlayback: 2,
};

export const Capability: any = {
  Play: "play",
  Pause: "pause",
  SkipToNext: "next",
  SkipToPrevious: "previous",
  SeekTo: "seek",
  Stop: "stop",
  JumpForward: "jumpForward",
  JumpBackward: "jumpBackward",
};

export const Event: any = {
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
};

export const RepeatMode: any = { Off: 0, Track: 1, Queue: 2 };
export const State: any = {
  None: 0,
  Ready: 1,
  Playing: 2,
  Paused: 3,
  Stopped: 4,
  Buffering: 5,
  Connecting: 6,
  Error: 7,
};
