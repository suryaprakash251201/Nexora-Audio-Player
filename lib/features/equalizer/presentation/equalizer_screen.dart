import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/audio_handler.dart';
import '../../../core/audio/equalizer_bridge.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/bright_icons.dart';
import '../../../ui/widgets/enhanced_glass.dart';

/// Gain range (dB) for every band and for the preamp.
const double kMinDb = -12;
const double kMaxDb = 12;

/// Frequency grid that presets are authored against. Presets are interpolated
/// onto whatever band layout the current platform exposes, which is what makes
/// the EQ adaptive rather than hard-coded to one band count.
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

/// Android's `android.media.audiofx.Equalizer` ships a 5-band layout, while
/// iOS `AVAudioUnitEQ` is typically configured with 10 octave bands. Desktop
/// and web get a balanced 8-band layout.
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
  final IconData icon;
  final BrightIconTone tone;
  final List<double> gains;
  const _Preset(this.name, this.icon, this.tone, this.gains);
}

final List<_Preset> _kPresets = [
  _Preset('Flat', Icons.horizontal_rule_rounded, BrightIconTone.sky, [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]),
  _Preset('Rock', Icons.speaker_rounded, BrightIconTone.rose, [
    5,
    3,
    -2,
    -3,
    -1,
    1,
    3,
    4,
    4,
    3,
  ]),
  _Preset('Pop', Icons.celebration_rounded, BrightIconTone.pink, [
    -1,
    1,
    3,
    4,
    3,
    0,
    -1,
    -1,
    -1,
    -1,
  ]),
  _Preset('Jazz', Icons.piano_rounded, BrightIconTone.amber, [
    3,
    2,
    1,
    2,
    -1,
    -1,
    0,
    1,
    2,
    3,
  ]),
  _Preset('Classical', Icons.theater_comedy_rounded, BrightIconTone.indigo, [
    4,
    3,
    2,
    1,
    -1,
    -1,
    0,
    2,
    3,
    4,
  ]),
  _Preset('Bass', Icons.graphic_eq_rounded, BrightIconTone.violet, [
    6,
    5,
    4,
    2,
    1,
    0,
    0,
    0,
    0,
    0,
  ]),
  _Preset('Treble', Icons.trending_up_rounded, BrightIconTone.cyan, [
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    3,
    5,
    6,
  ]),
  _Preset('Vocal', Icons.mic_rounded, BrightIconTone.emerald, [
    -2,
    -2,
    0,
    2,
    4,
    4,
    3,
    1,
    0,
    -1,
  ]),
  _Preset('Electronic', Icons.surround_sound_rounded, BrightIconTone.sky, [
    4,
    3,
    1,
    0,
    -1,
    0,
    1,
    2,
    3,
    4,
  ]),
  _Preset('Loudness', Icons.volume_up_rounded, BrightIconTone.rose, [
    5,
    4,
    2,
    0,
    -1,
    0,
    1,
    2,
    4,
    5,
  ]),
];

/// Interpolates a preset authored on [kPresetFreqs] onto an arbitrary band
/// centre frequency, using log-frequency interpolation.
double _gainAt(List<double> gains, double freq) {
  final n = kPresetFreqs.length;
  if (freq <= kPresetFreqs.first) return gains.first;
  if (freq >= kPresetFreqs.last) return gains.last;
  for (var i = 0; i < n - 1; i++) {
    final f0 = kPresetFreqs[i];
    final f1 = kPresetFreqs[i + 1];
    if (freq >= f0 && freq <= f1) {
      final t = (math.log(freq) - math.log(f0)) / (math.log(f1) - math.log(f0));
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
    } catch (_) {
      // Preferences unavailable — fall back to a flat curve.
    }
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
    } catch (_) {
      // Ignore persistence failures; the curve still applies for this session.
    }
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
        return 'Android · ${_specs.length}-band';
      case TargetPlatform.iOS:
        return 'iOS · ${_specs.length}-band';
      case TargetPlatform.macOS:
        return 'macOS · ${_specs.length}-band';
      case TargetPlatform.windows:
        return 'Windows · ${_specs.length}-band';
      case TargetPlatform.linux:
        return 'Linux · ${_specs.length}-band';
      case TargetPlatform.fuchsia:
        return 'Fuchsia · ${_specs.length}-band';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _headerCard(),
              const SizedBox(height: 16),
              _curveCard(),
              const SizedBox(height: 18),
              _presetsSection(),
              const SizedBox(height: 20),
              _bandsSection(),
              const SizedBox(height: 22),
              _actionsRow(),
              const SizedBox(height: 18),
              _engineNote(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _headerCard() {
    final enabled = _enabled;
    return EnhancedGlassSurface(
      opacity: 0.3,
      blur: 30,
      borderRadius: BorderRadius.circular(26),
      showInnerGlow: true,
      glowColor: enabled ? AppColors.secondary : AppColors.textDim,
      glowRadius: 40,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlassBrightIcon(
                  icon: Icons.graphic_eq_rounded,
                  tone: enabled ? BrightIconTone.cyan : BrightIconTone.sky,
                  size: 44,
                  iconSize: 24,
                  active: enabled,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audiophile EQ',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _platformLabel,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _enabled,
                  onChanged: (v) {
                    setState(() => _enabled = v);
                    unawaited(_persist());
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Bands adapt to the platform audio engine. Presets are authored '
              'on an octave grid and interpolated, so they sound consistent on '
              'both Android and iOS.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Response curve ──────────────────────────────────────────────────────

  Widget _curveCard() {
    return EnhancedGlassSurface(
      opacity: 0.26,
      blur: 26,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BrightIcon(
                  icon: Icons.show_chart_rounded,
                  size: 18,
                  tone: BrightIconTone.violet,
                ),
                const SizedBox(width: 8),
                Text(
                  'Frequency Response',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _enabled
                        ? AppColors.secondary.withValues(alpha: 0.14)
                        : AppColors.textDim.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _enabled ? 'ACTIVE' : 'BYPASS',
                    style: TextStyle(
                      color: _enabled
                          ? AppColors.secondaryLight
                          : AppColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: AnimatedOpacity(
                opacity: _enabled ? 1 : 0.4,
                duration: const Duration(milliseconds: 250),
                child: CustomPaint(
                  painter: _CurvePainter(
                    freqs: _specs.map((s) => s.freq).toList(),
                    gains: _bands,
                    preamp: _preamp,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _preampSlider(),
          ],
        ),
      ),
    );
  }

  Widget _preampSlider() {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            'Preamp',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
          width: 62,
          child: Text(
            '${_preamp >= 0 ? '+' : ''}${_preamp.toStringAsFixed(1)} dB',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ── Presets ─────────────────────────────────────────────────────────────

  Widget _presetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Presets',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: _kPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (c, i) {
              final p = _kPresets[i];
              final selected = _presetName == p.name;
              return _PresetCard(
                preset: p,
                selected: selected,
                onTap: () => _applyPreset(p),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Bands ───────────────────────────────────────────────────────────────

  Widget _bandsSection() {
    // 3 per row on phones keeps the vertical sliders comfortably thumb-sized.
    final crossAxisCount = _specs.length <= 5
        ? 5
        : (_specs.length <= 8 ? 4 : 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Bands',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${_specs.length} bands · ${kMinDb.toInt()} to +${kMaxDb.toInt()} dB',
                style: TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.62,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _specs.length,
          itemBuilder: (c, i) => _BandCard(
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
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Widget _actionsRow() {
    return Row(
      children: [
        Expanded(
          child: BrightIconChip(
            icon: Icons.restart_alt_rounded,
            label: 'Reset Flat',
            tone: BrightIconTone.sky,
            onTap: _resetFlat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BrightIconChip(
            icon: Icons.bookmark_add_rounded,
            label: 'Save Curve',
            tone: BrightIconTone.emerald,
            onTap: () {
              _persist();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('EQ curve saved on this device')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _engineNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This curve is stored by Nexora and sent to the platform bridge. '
              'Android applies it to just_audio\'s audio session when available. '
              'iOS configures AVAudioUnitEQ, but just_audio owns a separate '
              'graph here, so iOS does not claim to DSP playback yet. Desktop '
              'and web keep the settings as an unsupported fallback.',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRESET CARD
// ═══════════════════════════════════════════════════════════════

class _PresetCard extends StatelessWidget {
  final _Preset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preset.tone.stops;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [
                    colors.first.withValues(alpha: 0.3),
                    colors.last.withValues(alpha: 0.1),
                  ]
                : [
                    AppColors.glassBase.withValues(alpha: 0.35),
                    AppColors.glassBase.withValues(alpha: 0.14),
                  ],
          ),
          border: Border.all(
            color: selected
                ? colors.first.withValues(alpha: 0.5)
                : AppColors.glassBorder,
            width: 0.7,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrightIcon(
              icon: preset.icon,
              size: 24,
              tone: preset.tone,
              active: true,
            ),
            const SizedBox(height: 6),
            Text(
              preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? colors.first : AppColors.text,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BAND CARD
// ═══════════════════════════════════════════════════════════════

class _BandCard extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _BandCard({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != 0;
    // Cool below unity, warm above — reads like a real hardware EQ.
    final tone = value >= 0 ? BrightIconTone.cyan : BrightIconTone.amber;
    final accent = active ? tone.stops.first : AppColors.textDim;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.glassBase.withValues(alpha: 0.4),
            AppColors.glassBase.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(
          color: active ? accent.withValues(alpha: 0.4) : AppColors.glassBorder,
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? accent : AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: accent,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                  thumbColor: Colors.white,
                  overlayColor: accent.withValues(alpha: 0.18),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
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
          const SizedBox(height: 4),
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}',
            style: TextStyle(
              color: active ? accent : AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RESPONSE CURVE PAINTER
// ═══════════════════════════════════════════════════════════════

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

    // ── Grid ──
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.6;
    for (final f in [100, 1000, 10000]) {
      final x = _xFor(f.toDouble(), w);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    final zeroPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), zeroPaint);

    // ── Build smoothed points ──
    final pts = <Offset>[];
    pts.add(Offset(0, _yFor(gains.isEmpty ? 0 : gains.first, h)));
    for (var i = 0; i < freqs.length; i++) {
      pts.add(Offset(_xFor(freqs[i], w), _yFor(gains[i], h)));
    }
    pts.add(Offset(w, _yFor(gains.isEmpty ? 0 : gains.last, h)));

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    // Catmull-Rom style smoothing between band centres.
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

    // ── Fill under curve ──
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.secondary.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // ── Stroke ──
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.secondaryLight, AppColors.primaryLight],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.2);
    canvas.drawPath(path, strokePaint);

    // ── Band nodes ──
    for (var i = 0; i < freqs.length; i++) {
      final x = _xFor(freqs[i], w);
      final y = _yFor(gains[i], h);
      canvas.drawCircle(
        Offset(x, y),
        3.4,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        Offset(x, y),
        6.5,
        Paint()
          ..color = (gains[i] >= 0 ? AppColors.secondary : AppColors.tertiary)
              .withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.gains != gains || old.preamp != preamp || old.freqs != freqs;
}
