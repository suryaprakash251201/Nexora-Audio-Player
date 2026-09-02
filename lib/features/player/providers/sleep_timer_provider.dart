import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_provider.dart';

/// State for the sleep timer.
class SleepTimerState {
  final bool isActive;
  final Duration? total;
  final Duration? remaining;
  final bool fadeOut;

  const SleepTimerState({this.isActive = false, this.total, this.remaining})
    : fadeOut = true;

  const SleepTimerState.inactive() : this(isActive: false);

  SleepTimerState copyWith({
    bool? isActive,
    Duration? total,
    Duration? remaining,
  }) => SleepTimerState(
    isActive: isActive ?? this.isActive,
    total: total ?? this.total,
    remaining: remaining ?? this.remaining,
  );

  String get label {
    if (!isActive || remaining == null) return 'Off';
    final r = remaining!;
    if (r.inHours > 0) {
      return '${r.inHours}h ${r.inMinutes % 60}m left';
    }
    if (r.inMinutes > 0) {
      final s = r.inSeconds % 60;
      return s == 0 ? '${r.inMinutes}m left' : '${r.inMinutes}m ${s}s left';
    }
    return '${r.inSeconds}s left';
  }

  double get progress {
    if (!isActive || total == null || remaining == null) return 0;
    final t = total!.inSeconds;
    if (t == 0) return 0;
    return (remaining!.inSeconds / t).clamp(0.0, 1.0);
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>(
      (ref) => SleepTimerNotifier(ref),
    );

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _ticker;
  Timer? _fadeTicker;
  double? _originalVolume;

  SleepTimerNotifier(this._ref) : super(const SleepTimerState.inactive());

  /// Preset durations offered in UI.
  static const presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
    Duration(minutes: 120),
  ];

  void setTimer(Duration duration) {
    _cancelTickers();
    if (duration.inSeconds <= 0) {
      state = const SleepTimerState.inactive();
      return;
    }
    state = SleepTimerState(
      isActive: true,
      total: duration,
      remaining: duration,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void extend(Duration extra) {
    if (!state.isActive || state.remaining == null) return;
    final newRemaining = state.remaining! + extra;
    final newTotal = (state.total ?? Duration.zero) + extra;
    state = state.copyWith(total: newTotal, remaining: newRemaining);
  }

  void cancel() {
    _cancelTickers();
    // Restore volume if we were fading
    if (_originalVolume != null) {
      unawaited(_ref.read(playerProvider.notifier).setVolume(_originalVolume!));
      _originalVolume = null;
    }
    state = const SleepTimerState.inactive();
  }

  void _tick() {
    if (!state.isActive || state.remaining == null) return;
    final next = state.remaining! - const Duration(seconds: 1);
    if (next.inSeconds <= 0) {
      state = state.copyWith(remaining: Duration.zero);
      _onExpired();
      return;
    }
    state = state.copyWith(remaining: next);

    // Start fade-out in last 12 seconds
    if (next.inSeconds <= 12 && next.inSeconds > 0) {
      _startFadeIfNeeded();
    }
  }

  void _startFadeIfNeeded() {
    if (_fadeTicker != null) return;
    final player = _ref.read(playerProvider);
    _originalVolume ??= player.volume;
    // Fade linearly over remaining seconds
    _fadeTicker = Timer.periodic(const Duration(milliseconds: 800), (t) {
      final rem = state.remaining?.inSeconds ?? 0;
      if (rem <= 0) {
        t.cancel();
        return;
      }
      // Fade from originalVolume to 0 over 12s
      final factor = (rem / 12).clamp(0.0, 1.0);
      final vol = (_originalVolume ?? 1.0) * factor;
      unawaited(
        _ref.read(playerProvider.notifier).setVolume(vol.clamp(0.0, 1.0)),
      );
    });
  }

  Future<void> _onExpired() async {
    _ticker?.cancel();
    _fadeTicker?.cancel();
    // Pause playback
    try {
      await _ref.read(playerProvider.notifier).pause();
    } catch (_) {}
    // Restore volume after short delay for next play
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_originalVolume != null) {
      try {
        await _ref.read(playerProvider.notifier).setVolume(_originalVolume!);
      } catch (_) {}
      _originalVolume = null;
    }
    state = const SleepTimerState.inactive();
  }

  void _cancelTickers() {
    _ticker?.cancel();
    _ticker = null;
    _fadeTicker?.cancel();
    _fadeTicker = null;
  }

  @override
  void dispose() {
    _cancelTickers();
    super.dispose();
  }
}

/// Human readable duration.
String formatSleepDuration(Duration d) {
  if (d.inHours > 0) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
  return '${d.inMinutes}m';
}
