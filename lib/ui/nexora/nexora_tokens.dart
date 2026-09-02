/// Nexora design tokens.
///
/// Centralized spacing, radius, motion, shadows and visual modes.
/// Colors and typography live in [AppColors] / [AppTypography].
/// Everything tactile — rhythm, shape, elevation, duration — lives here.
library;

import 'package:flutter/widgets.dart';

class NexoraSpacing {
  NexoraSpacing._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: 20,
  );
  static const EdgeInsets screenHorizontalTight = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets screenAll = EdgeInsets.all(20);
  static const EdgeInsets screenGutter = EdgeInsets.fromLTRB(20, 12, 20, 20);

  /// Reserve above the floating dock so lists never hide behind it.
  static const double dockBottomReserve = 148;

  /// Section gap between settings groups.
  static const double sectionGap = 20;
}

class NexoraRadius {
  NexoraRadius._();

  static const double r4 = 4;
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;

  static const BorderRadius artwork = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(r10));
  static const BorderRadius button = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(24),
  );
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(20));
}

class NexoraShadow {
  NexoraShadow._();

  /// Soft card shadow — default elevation for grouped cards.
  static List<BoxShadow> card(bool isDark) => [
    BoxShadow(
      color: isDark
          ? const Color(0xFF000000).withValues(alpha: 0.30)
          : const Color(0xFF1A2A4A).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: isDark
          ? const Color(0xFF000000).withValues(alpha: 0.18)
          : const Color(0xFF1A2A4A).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Stronger shadow for floating chrome (nav, mini player).
  static List<BoxShadow> floating(bool isDark) => [
    BoxShadow(
      color: isDark
          ? const Color(0xFF000000).withValues(alpha: 0.45)
          : const Color(0xFF1A2A4A).withValues(alpha: 0.14),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: isDark
          ? const Color(0xFF000000).withValues(alpha: 0.22)
          : const Color(0xFF1A2A4A).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  /// Subtle inner glow for the selected nav pill.
  static List<BoxShadow> pill(bool isDark) => [
    BoxShadow(
      color: const Color(0xFF3A7BFF).withValues(alpha: isDark ? 0.22 : 0.16),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];
}

class NexoraDuration {
  NexoraDuration._();

  static const Duration tap = Duration(milliseconds: 120);
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration crossfade = Duration(milliseconds: 420);
  static const Duration trackSwap = Duration(milliseconds: 360);
  static const Duration navSpring = Duration(milliseconds: 480);
  static const Duration sheet = Duration(milliseconds: 380);
}

/// Visual mode for the full-player artwork stage.
enum PlayerVisualMode {
  /// Calm dark canvas, sharp square artwork.
  modern,

  /// Rotating round record.
  vinyl,

  /// Cassette-tape inspired stage.
  cassette,

  /// Stripped-down: only artwork + title.
  minimal,
}

extension PlayerVisualModeLabel on PlayerVisualMode {
  String get label {
    switch (this) {
      case PlayerVisualMode.modern:
        return 'Modern';
      case PlayerVisualMode.vinyl:
        return 'Vinyl';
      case PlayerVisualMode.cassette:
        return 'Cassette';
      case PlayerVisualMode.minimal:
        return 'Minimal';
    }
  }
}
