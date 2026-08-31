/**
 * Thin singleton wrapper around `react-native-track-player`.
 *
 * Why this exists:
 *  - Keep one well-tested controller for everything that touches playback
 *    (queue mutations, lock-screen commands, audio focus, retry on codec
 *    init failure) so the React side doesn't need to know about TrackPlayer's
 *    async surface.
 *  - Provide a small synchronous-looking facade (play/pause/seek/skip) plus
 *    an event bus the rest of the app subscribes to.
 *  - Bridge to a parallel `react-native-audio-api` source in M5/M6 (real DSP
 *    + analyzer). For M1 we just expose the RNTP controller.
 *
 * Mirrors the public API of upstream Nexora's `trackPlayerController` but
 * without the upstream-specific `audioStreamUrl` transcode routing (that
 * lives in `src/audio/streamRouter.ts` so the controller stays
 * audio-source-agnostic).
 */
import {
  TrackPlayer,
  AppKilledPlaybackBehavior,
  Capability,
  Event,
  RepeatMode,
  State,
} from "./trackPlayerShim";

export type Repeat = "off" | "track" | "queue";

export type ControllerEvent =
  | "playingChange"
  | "statusChange"
  | "timeUpdate"
  | "ended"
  | "activeTrackChanged";

export type Listener = (payload: any) => void;

let initialised = false;
let initPromise: Promise<void> | null = null;
let pollTimer: ReturnType<typeof setInterval> | null = null;

class PlayerController {
  private listeners = new Map<ControllerEvent, Set<Listener>>();

  status: "idle" | "loading" | "readyToPlay" | "error" = "idle";
  playing = false;
  currentTime = 0;
  duration = 0;
  buffered = 0;
  currentIndex: number = -1;
  trackId: string | null = null;
  loop: Repeat = "off";

  remoteHandlers: { next?: () => void; previous?: () => void } = {};

  async ensureInit(): Promise<void> {
    if (initialised) return;
    if (initPromise) return initPromise;
    initPromise = (async () => {
      try {
        await TrackPlayer.setupPlayer({ autoHandleInterruptions: true });
      } catch (e: any) {
        // setupPlayer throws "The player has already been initialized" on hot
        // reload — swallow. Also swallow iOS "already setup" variants.
        const msg = String(e?.message || e).toLowerCase();
        if (!msg.includes("already been initialized") && !msg.includes("already")) throw e;
      }
      await TrackPlayer.updateOptions({
        android: {
          appKilledPlaybackBehavior: AppKilledPlaybackBehavior.ContinuePlayback,
        },
        capabilities: [
          Capability.Play,
          Capability.Pause,
          Capability.SkipToNext,
          Capability.SkipToPrevious,
          Capability.SeekTo,
          Capability.Stop,
          Capability.JumpForward,
          Capability.JumpBackward,
        ],
        compactCapabilities: [
          Capability.Play,
          Capability.Pause,
          Capability.SkipToNext,
          Capability.SkipToPrevious,
        ],
        progressUpdateEventInterval: 1,
        forwardJumpInterval: 15,
        backwardJumpInterval: 15,
      });

      TrackPlayer.addEventListener(Event.PlaybackState, (e: any) => {
        this.status = mapState(e.state);
        this.playing = e.state === State.Playing;
        this.emit("statusChange", { status: this.status });
        this.emit("playingChange", { playing: this.playing });
      });

      TrackPlayer.addEventListener(Event.PlaybackActiveTrackChanged, (e: any) => {
        const t = (e as any).track;
        this.trackId = t?.id ?? null;
        this.currentIndex = (e as any).lastIndex ?? -1;
        this.emit("activeTrackChanged", { track: t, index: this.currentIndex });
      });

      TrackPlayer.addEventListener(Event.PlaybackQueueEnded, () => {
        this.emit("ended", {});
      });

      TrackPlayer.addEventListener(Event.PlaybackError, (e: any) => {
        this.status = "error";
        this.emit("statusChange", { status: "error", error: e });
        // Prevent native unhandled error from killing JS context on iOS
        // RNTP emits PlaybackError for 401/404/stream decode failures — keep app alive.
        console.warn("[player] PlaybackError", e?.message || e);
      });

      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(() => void this.poll(), 500);

      TrackPlayer.addEventListener(Event.RemoteNext, () => this.remoteHandlers.next?.());
      TrackPlayer.addEventListener(Event.RemotePrevious, () => this.remoteHandlers.previous?.());

      initialised = true;
    })();
    try {
      await initPromise;
    } finally {
      // allow retry if init failed
      if (!initialised) initPromise = null;
    }
  }

  private async poll() {
    try {
      const p = await TrackPlayer.getProgress();
      this.currentTime = p.position;
      this.duration = p.duration;
      this.buffered = p.buffered;
      this.emit("timeUpdate", { currentTime: this.currentTime, duration: this.duration });
    } catch {
      // ignore — progress polls during teardown throw
    }
  }

  on(event: ControllerEvent, handler: Listener): () => void {
    let set = this.listeners.get(event);
    if (!set) {
      set = new Set();
      this.listeners.set(event, set);
    }
    set.add(handler);
    return () => set!.delete(handler);
  }

  private emit(event: ControllerEvent, payload: any) {
    this.listeners.get(event)?.forEach((h) => {
      try {
        h(payload);
      } catch {
        // listener errors must never break playback
      }
    });
  }

  async play() {
    await TrackPlayer.play();
  }
  async pause() {
    await TrackPlayer.pause();
  }
  async seekBy(deltaSec: number) {
    await TrackPlayer.seekBy(deltaSec);
  }
  async seekTo(seconds: number) {
    const dur = this.duration || 1;
    await TrackPlayer.seekTo(Math.max(0, Math.min(seconds, dur - 0.05)));
  }
  async reset() {
    await TrackPlayer.reset();
  }

  async setRepeat(mode: Repeat) {
    this.loop = mode;
    await TrackPlayer.setRepeatMode(
      mode === "track" ? RepeatMode.Track : RepeatMode.Off,
    );
  }

  setVolume(v: number) {
    return TrackPlayer.setVolume(Math.max(0, Math.min(1, v)));
  }

  async replaceQueue(tracks: Array<{ id: string; url: string; title: string; artist: string; artwork?: string; duration?: number; headers?: Record<string,string> }>) {
    // Guard: RNTP on iOS crashes if add() receives tracks with invalid url (e.g. ph://, empty).
    const safe = tracks.filter(t => typeof t.url === "string" && t.url.length > 4 && !t.url.startsWith("ph://"));
    if (!safe.length) throw new Error("No playable URLs (check ph:// on iOS or auth token)");
    await TrackPlayer.reset();
    await TrackPlayer.add(safe as any);
  }

  async addToQueue(tracks: Array<{ id: string; url: string; title: string; artist: string; artwork?: string; duration?: number; headers?: Record<string,string> }>) {
    const safe = tracks.filter(t => typeof t.url === "string" && t.url.length > 4 && !t.url.startsWith("ph://"));
    if (!safe.length) throw new Error("No playable URLs");
    await TrackPlayer.add(safe as any);
  }

  async skipToIndex(index: number, _initial = false) {
    if (index < 0) throw new Error(`skipToIndex: invalid index ${index}`);
    this.currentIndex = index;
    await TrackPlayer.skip(index);
  }

  async removeTrack(index: number) {
    await TrackPlayer.remove(index);
  }
}

function mapState(s: typeof State[keyof typeof State]): "idle" | "loading" | "readyToPlay" | "error" {
  switch (s) {
    case State.None:
      return "idle";
    case State.Buffering:
    case State.Connecting:
      return "loading";
    case State.Ready:
      return "readyToPlay";
    case State.Error:
      return "error";
    default:
      return "idle";
  }
}

export const player = new PlayerController();