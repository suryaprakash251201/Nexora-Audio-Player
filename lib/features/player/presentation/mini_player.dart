import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/nexora/nexora_mini_player.dart';

/// Thin wrapper that lets router.dart's _BottomDock continue to compose
/// the persistent mini player while delegating the actual UI to the new
/// Nexora design system.
class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NexoraMiniPlayer(onTap: onTap);
  }
}