/// Nexora design tokens.
///
/// Centralized spacing, radius, motion, and visual-mode values for the
/// Hi-Fi redesign. The existing [AppColors] / [AppTypography] modules own
/// color and type. This module owns everything else: rhythm, shape,
/// durations, and the [PlayerVisualMode] enum used across the player
/// surfaces.
///
/// Anything that wants to feel like the same product should read from
/// here instead of hard-coding magic numbers.
library;

import 'package:flutter/widgets.dart';

class NexoraSpacing {
  NexoraSpacing._();

  /// 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 — the only spacing values
  /// used in the redesign. Don't introduce new steps.
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  /// Compact screen-edge padding.
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets screenHorizontalTight =
      EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets screenAll = EdgeInsets.all(20);

  /// Bottom inset that lives above the mini-player + nav dock.
  static const double dockBottomReserve = 160;
}

class NexoraRadius {
  NexoraRadius._();

  static const double r4 = 4;
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;

  /// Album artwork stays close to square with a small radius.
  static const BorderRadius artwork = BorderRadius.all(Radius.circular(r8));

  /// Buttons and chips get a slightly softer corner.
  static const BorderRadius chip = BorderRadius.all(Radius.circular(r10));
  static const BorderRadius button = BorderRadius.all(Radius.circular(r12));

  /// Bottom sheets.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(20),
  );

  /// Cards.
  static const BorderRadius card = BorderRadius.all(Radius.circular(r16));
}

class NexoraDuration {
  NexoraDuration._();

  /// Animation timings — kept short and deliberate.
  static const Duration tap = Duration(milliseconds: 120);
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration crossfade = Duration(milliseconds: 420);

  /// Player artwork crossfade on track change.
  static const Duration trackSwap = Duration(milliseconds: 360);
}

/// Optional visual mode for the full-player artwork stage.
///
/// The default [modern] is the calm, premium signature screen. The other
/// modes preserve the existing distinct player personalities as opt-in
/// alternatives without forcing them on every listener.
enum PlayerVisualMode {
  /// Calm dark canvas, sharp square artwork, Hi-Fi metadata.
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