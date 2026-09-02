import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/audio_handler.dart';
import '../../../core/audio/equalizer_bridge.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_settings_row.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';

/// Gain range (dB) for every band and for the preamp.
const double kMinDb = -12;
const double kMaxDb = 12;

/// Frequency grid that presets are authored against.
const List<double> kPresetFreqs = [
  32,
  64,
  125,
  250,
  500,
  1000,
  2000,
  4000,
  8000,
  16000,
];

class _BandSpec {
  final String label;
  final double freq;
  const _BandSpec(this.label, this.freq);
}

List<_BandSpec> _bandsForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
      return const [
        _BandSpec('60', 60),
        _BandSpec('230', 230),
        _BandSpec('910', 910),
        _BandSpec('3.6k', 3600),
        _BandSpec('14k', 14000),
      ];
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return const [
        _BandSpec('32', 32),
        _BandSpec('64', 64),
        _BandSpec('125', 125),
        _BandSpec('250', 250),
        _BandSpec('500', 500),
        _BandSpec('1k', 1000),
        _BandSpec('2k', 2000),
        _BandSpec('4k', 4000),
        _BandSpec('8k', 8000),
        _BandSpec('16k', 16000),
      ];
    default:
      return const [
        _BandSpec('60', 60),
        _BandSpec('150', 150),
        _BandSpec('400', 400),
        _BandSpec('1k', 1000),
        _BandSpec('2.4k', 2400),
        _BandSpec('6k', 6000),
        _BandSpec('12k', 12000),
        _BandSpec('16k', 16000),
      ];
  }
}

class _Preset {
  final String name;
  final List<double> gains;
  const _Preset(this.name, this.gains);
}

final List<_Preset> _kPresets = [
  _Preset('Flat', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  _Preset('Rock', [5, 3, -2, -3, -1, 1, 3, 4, 4, 3]),
  _Preset('Pop', [-1, 1, 3, 4, 3, 0, -1, -1, -1, -1]),
  _Preset('Jazz', [3, 2, 1, 2, -1, -1, 0, 1, 2, 3]),
  _Preset('Classical', [4, 3, 2, 1, -1, -1, 0, 2, 3, 4]),
  _Preset('Bass', [6, 5, 4, 2, 1, 0, 0, 0, 0, 0]),
  _Preset('Treble', [0, 0, 0, 0, 0, 0, 2, 3, 5, 6]),
  _Preset('Vocal', [-2, -2, 0, 2, 4, 4, 3, 1, 0, -1]),
  _Preset('Electronic', [4, 3, 1, 0, -1, 0, 1, 2, 3, 4]),
  _Preset('Loudness', [5, 4, 2, 0, -1, 0, 1, 2, 4, 5]),
];

double _gainAt(List<double> gains, double freq) {
  final n = kPresetFreqs.length;
  if (freq <= kPresetFreqs.first) return gains.first;
  if (freq >= kPresetFreqs.last) return gains.last;
  for (var i = 0; i < n - 1; i++) {
    final f0 = kPresetFreqs[i];
    final f1 = kPresetFreqs[i + 1];
    if (freq >= f0 && freq <= f1) {
      final t = (math.log(freq) - math.log(f0)) /
          (math.log(f1) - math.log(f0));
      return gains[i] + (gains[i + 1] - gains[i]) * t;
    }
  }
  return gains.last;
}

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});
  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  late final List<_BandSpec> _specs;
  late List<double> _bands;
  double _preamp = 0;
  bool _enabled = true;
  String? _presetName;
  bool _loading = true;
  StreamSubscription<int?>? _sessionSub;

  static const String _keyEnabled = 'eq_enabled';
  static const String _keyPreamp = 'eq_preamp';
  static const String _keyBands = 'eq_bands';

  @override
  void initState() {
    super.initState();
    _specs = _bandsForPlatform(defaultTargetPlatform);
    _bands = List.filled(_specs.length, 0);
    final player = ref.read(audioHandlerProvider).player;
    _sessionSub = player.androidAudioSessionIdStream.listen((_) {
      unawaited(_applyNative());
    });
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyBands);
      if (saved != null && saved.isNotEmpty) {
        final parts = saved.split(',');
        if (parts.length == _specs.length) {
          _bands = parts
              .map((p) => (double.tryParse(p) ?? 0).clamp(kMinDb, kMaxDb))
              .toList();
        }
      }
      _preamp = (prefs.getDouble(_keyPreamp) ?? 0).clamp(kMinDb, kMaxDb);
      _enabled = prefs.getBool(_keyEnabled) ?? true;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    await _applyNative();
  }

  Future<void> _applyNative() {
    final player = ref.read(audioHandlerProvider).player;
    return EqualizerBridge.apply(
      enabled: _enabled,
      preamp: _preamp,
      frequencies: _specs.map((spec) => spec.freq).toList(),
      gains: _bands,
      audioSessionId: player.androidAudioSessionId,
    );
  }

  Future<void> _persist() async {
    await _applyNative();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyBands,
        _bands.map((b) => b.toStringAsFixed(1)).join(','),
      );
      await prefs.setDouble(_keyPreamp, _preamp);
      await prefs.setBool(_keyEnabled, _enabled);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _applyPreset(_Preset preset) {
    setState(() {
      _presetName = preset.name;
      _bands = [
        for (final spec in _specs)
          _gainAt(preset.gains, spec.freq).clamp(kMinDb, kMaxDb),
      ];
    });
    _persist();
  }

  void _resetFlat() {
    setState(() {
      _presetName = 'Flat';
      _preamp = 0;
      _bands = List.filled(_specs.length, 0);
    });
    _persist();
  }

  String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID · ${_specs.length}-BAND';
      case TargetPlatform.iOS:
        return 'IOS · ${_specs.length}-BAND';
      case TargetPlatform.macOS:
        return 'MACOS · ${_specs.length}-BAND';
      case TargetPlatform.windows:
        return 'WINDOWS · ${_specs.length}-BAND';
      case TargetPlatform.linux:
        return 'LINUX · ${_specs.length}-BAND';
      case TargetPlatform.fuchsia:
        return 'FUCHSIA · ${_specs.length}-BAND';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Equalizer',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          children: [
            NexoraGroupedList(
              padding: EdgeInsets.zero,
              children: [
                NexoraSettingsRow(
                  icon: Icons.graphic_eq_rounded,
                  title: _enabled ? 'Equalizer enabled' : 'Equalizer bypass',
                  subtitle: _platformLabel,
                  trailing: Switch.adaptive(
                    value: _enabled,
                    onChanged: (v) {
                      setState(() => _enabled = v);
                      unawaited(_persist());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: NexoraSpacing.s24),
            const NexoraSectionHeader(label: 'Response Curve'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s16),
              padding: const EdgeInsets.all(NexoraSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: NexoraRadius.card,
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: AnimatedOpacity(
                      opacity: _enabled ? 1 : 0.35,
                      duration: NexoraDuration.short,
                      child: CustomPaint(
                        painter: _CurvePainter(
                          freqs: _specs.map((s) => s.freq).toList(),
                          gains: _bands,
                          preamp: _preamp,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: NexoraSpacing.s16),
                  _preampSlider(),
                ],
              ),
            ),
            const SizedBox(height: NexoraSpacing.s24),
            const NexoraSectionHeader(label: 'Presets'),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s16),
                itemCount: _kPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final p = _kPresets[i];
                  final selected = _presetName == p.name;
                  return GestureDetector(
                    onTap: () => _applyPreset(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NexoraSpacing.s16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: NexoraRadius.button,
                        border: Border.all(
                          color: selected
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.border,
                          width: 0.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.name,
                        style: TextStyle(
                          color: selected ? AppColors.accent : AppColors.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: NexoraSpacing.s24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'BANDS',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_specs.length} BANDS · ${kMinDb.toInt()} TO +${kMaxDb.toInt()} dB',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s16),
              padding: const EdgeInsets.fromLTRB(
                NexoraSpacing.s16,
                NexoraSpacing.s20,
                NexoraSpacing.s16,
                NexoraSpacing.s16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: NexoraRadius.card,
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _specs.length; i++)
                    Expanded(
                      child: _BandSlider(
                        label: _specs[i].label,
                        value: _bands[i],
                        onChanged: (v) {
                          setState(() {
                            _bands[i] = v;
                            _presetName = null;
                          });
                          unawaited(_applyNative());
                        },
                        onChangeEnd: (_) => _persist(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: NexoraSpacing.s24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s16),
              child: Row(
                children: [
                  Expanded(
                    child: NexoraTextButton(
                      label: 'Reset Flat',
                      icon: Icons.restart_alt_rounded,
                      onTap: _resetFlat,
                    ),
                  ),
                  const SizedBox(width: NexoraSpacing.s12),
                  Expanded(
                    child: NexoraTextButton(
                      label: 'Save Curve',
                      icon: Icons.bookmark_add_rounded,
                      primary: true,
                      onTap: () {
                        _persist();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('EQ curve saved on this device'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NexoraSpacing.s20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s16),
              child: Container(
                padding: const EdgeInsets.all(NexoraSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: NexoraRadius.card,
                  border: Border.all(color: AppColors.border, width: 0.6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: NexoraSpacing.s12),
                    Expanded(
                      child: Text(
                        'Curve is stored locally and routed to the platform audio engine. '
                        'Android applies it via just_audio\'s session; iOS configures AVAudioUnitEQ '
                        'when present. If the platform cannot apply DSP, the curve is kept as '
                        'an unsupported fallback.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preampSlider() {
    return Row(
      children: [
        const SizedBox(
          width: 60,
          child: Text(
            'PREAMP',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHigh,
              thumbColor: AppColors.text,
              overlayColor: AppColors.accent.withValues(alpha: 0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _preamp,
              min: kMinDb,
              max: kMaxDb,
              onChanged: (v) {
                setState(() {
                  _preamp = v;
                  _presetName = null;
                });
                unawaited(_applyNative());
              },
              onChangeEnd: (_) => _persist(),
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            '${_preamp >= 0 ? '+' : ''}${_preamp.toStringAsFixed(1)} dB',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _BandSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  const _BandSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final active = value.abs() > 0.05;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 160,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surfaceHigh,
                thumbColor: AppColors.text,
                overlayColor: AppColors.accent.withValues(alpha: 0.16),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value,
                min: kMinDb,
                max: kMaxDb,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}',
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<double> freqs;
  final List<double> gains;
  final double preamp;

  _CurvePainter({
    required this.freqs,
    required this.gains,
    required this.preamp,
  });

  static const double _minFreq = 20;
  static const double _maxFreq = 20000;

  double _xFor(double freq, double width) {
    final lo = math.log(_minFreq);
    final hi = math.log(_maxFreq);
    return ((math.log(freq.clamp(_minFreq, _maxFreq)) - lo) / (hi - lo)) *
        width;
  }

  double _yFor(double db, double height) {
    final t = ((db + preamp) - kMinDb) / (kMaxDb - kMinDb);
    return height - t.clamp(0.0, 1.0) * height;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AppColors.textDim.withValues(alpha: 0.16)
      ..strokeWidth = 0.5;
    for (final f in [100, 1000, 10000]) {
      final x = _xFor(f.toDouble(), w);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    final zeroPaint = Paint()
      ..color = AppColors.textDim.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), zeroPaint);

    final pts = <Offset>[];
    pts.add(Offset(0, _yFor(gains.isEmpty ? 0 : gains.first, h)));
    for (var i = 0; i < freqs.length; i++) {
      pts.add(Offset(_xFor(freqs[i], w), _yFor(gains[i], h)));
    }
    pts.add(Offset(w, _yFor(gains.isEmpty ? 0 : gains.last, h)));

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i == 0 ? 0 : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[(i + 2).clamp(0, pts.length - 1)];
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0.22),
          AppColors.accent.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    for (var i = 0; i < freqs.length; i++) {
      final x = _xFor(freqs[i], w);
      final y = _yFor(gains[i], h);
      canvas.drawCircle(
        Offset(x, y),
        4.5,
        Paint()
      ..color = AppColors.accent.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        Offset(x, y),
        2.5,
        Paint()..color = AppColors.text,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.gains != gains ||
      old.preamp != preamp ||
      old.freqs != freqs;
}