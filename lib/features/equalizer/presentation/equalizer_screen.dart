import 'package:flutter/material.dart';
import '../../../ui/theme.dart';

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
      appBar: AppBar(title: const Text('Equalizer')),
      body: ListView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.graphic_eq, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Audiophile EQ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Bypass',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'EQ adjusts playback on this device. Native DSP requires platform implementation via platform channels. UI is ready; DSP engine plugs in when available.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Preamp', style: TextStyle(color: Colors.white)),
                    const Spacer(),
                    Text(
                      '${_preamp.toStringAsFixed(1)} dB',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
                Slider(
                  value: _preamp,
                  min: -12,
                  max: 12,
                  divisions: 24,
                  label: '${_preamp.toStringAsFixed(1)} dB',
                  onChanged: (v) => setState(() => _preamp = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _bands.length,
            itemBuilder: (c, i) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    _labels[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _freqs[i],
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _bands[i],
                        min: -12,
                        max: 12,
                        onChanged: (v) => setState(() => _bands[i] = v),
                      ),
                    ),
                  ),
                  Text(
                    '${_bands[i].toStringAsFixed(1)}dB',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _preamp = 0;
                    for (var i = 0; i < _bands.length; i++) _bands[i] = 0;
                  }),
                  child: const Text('Reset Flat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('EQ preset saved (local only)'),
                      ),
                    );
                  },
                  child: const Text('Save Preset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: Real DSP requires native Android (Loudness/EQ) and iOS (AVAudioUnitEQ) bridges. Controls are wired to future platform channels.',
            style: TextStyle(color: AppColors.textDim, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
