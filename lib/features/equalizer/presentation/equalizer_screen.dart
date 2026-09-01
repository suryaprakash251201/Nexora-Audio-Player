import 'package:flutter/material.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/premium_widgets.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});
  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  double _preamp = 0;
  final List<double> _bands = List.filled(8, 0);
  final List<String> _labels = [
    'Sub',
    'Bass',
    'Low Mids',
    'Mids',
    'Upper Mids',
    'Presence',
    'Treble',
    'Air',
  ];
  final List<String> _freqs = [
    '60Hz',
    '230Hz',
    '910Hz',
    '3kHz',
    '4kHz',
    '6kHz',
    '12kHz',
    '16kHz',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Equalizer'),
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedGradientBg(
        colors: const [
          AppColors.primary,
          AppColors.secondary,
          AppColors.tertiary,
        ],
        blur: 60,
        child: ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          children: [
            // Preamp card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.glassBase.withValues(alpha: 0.8),
                    AppColors.surface.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Audiophile EQ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Row(
                          children: [
                            GlowDot(size: 5, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text(
                              'BYPASS',
                              style: TextStyle(
                                color: AppColors.secondaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Adjust playback for a richer soundstage. Native DSP plugs in when available.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Preamp',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_preamp.toStringAsFixed(1)} dB',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _preamp,
                    min: -12,
                    max: 12,
                    divisions: 24,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceRaised,
                    label: '${_preamp.toStringAsFixed(1)} dB',
                    onChanged: (v) => setState(() => _preamp = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Band grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _bands.length,
              itemBuilder: (c, i) => _BandCard(
                label: _labels[i],
                freq: _freqs[i],
                value: _bands[i],
                isActive: _bands[i] != 0,
                onChanged: (v) => setState(() => _bands[i] = v),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _preamp = 0;
                      for (var i = 0; i < _bands.length; i++) _bands[i] = 0;
                    }),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset Flat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('EQ preset saved (local only)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Preset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textDim,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Real DSP requires native Android (Loudness/EQ) and iOS (AVAudioUnitEQ) bridges.',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandCard extends StatelessWidget {
  final String label;
  final String freq;
  final double value;
  final bool isActive;
  final ValueChanged<double> onChanged;

  const _BandCard({
    required this.label,
    required this.freq,
    required this.value,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isActive ? AppColors.primary : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.glassBase.withValues(alpha: 0.7),
            AppColors.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? accent.withValues(alpha: 0.4) : AppColors.border,
          width: 0.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? accent : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            freq,
            style: const TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: value,
                min: -12,
                max: 12,
                activeColor: accent,
                inactiveColor: AppColors.surfaceRaised,
                onChanged: onChanged,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}dB',
            style: TextStyle(
              color: isActive ? accent : AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
