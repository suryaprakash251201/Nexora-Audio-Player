import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Active app theme mode. Dark is the immersive listening environment;
/// light is an airy, paper-inspired companion with real depth.
enum AppThemeMode { dark, light }

/// Centralized design tokens for Nexora 2.0.
///
/// Palette philosophy — "Midnight Aurora":
/// deep space blacks, frosted glass, and a signature violet → blue → cyan
/// aurora gradient. Single accent for meaning, gradient for moments of
/// delight (play buttons, progress, hero cards).
class AppColors {
  AppColors._();

  static AppThemeMode mode = AppThemeMode.dark;

  // ── Backgrounds ─────────────────────────────────────────────
  // Dark: deep space — richer than pure black, tuned for OLED + artwork pop.
  // Light: frosted mist — cool, airy, cards float as pure white.
  static const Color _backgroundDark = Color(0xFF06070C);
  static const Color _backgroundLight = Color(0xFFF4F5FA);
  static Color get background =>
      mode == AppThemeMode.dark ? _backgroundDark : _backgroundLight;

  static const Color _surfaceDark = Color(0xFF0C0F16);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static Color get surface =>
      mode == AppThemeMode.dark ? _surfaceDark : _surfaceLight;

  static const Color _surfaceRaisedDark = Color(0xFF141927);
  static const Color _surfaceRaisedLight = Color(0xFFEBEEF5);
  static Color get surfaceRaised =>
      mode == AppThemeMode.dark ? _surfaceRaisedDark : _surfaceRaisedLight;

  static const Color _surfaceHighDark = Color(0xFF1E2639);
  static const Color _surfaceHighLight = Color(0xFFDDE3F0);
  static Color get surfaceHigh =>
      mode == AppThemeMode.dark ? _surfaceHighDark : _surfaceHighLight;

  // Card-specific elevation surfaces
  static const Color _cardDark = Color(0xFF0E1320);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static Color get card => mode == AppThemeMode.dark ? _cardDark : _cardLight;

  static const Color _cardElevatedDark = Color(0xFF182038);
  static const Color _cardElevatedLight = Color(0xFFFFFFFF);
  static Color get cardElevated =>
      mode == AppThemeMode.dark ? _cardElevatedDark : _cardElevatedLight;

  // ── Borders ────────────────────────────────────────────────
  static const Color _borderDark = Color(0xFF222B42);
  static const Color _borderLight = Color(0xFFE1E6F1);
  static Color get border =>
      mode == AppThemeMode.dark ? _borderDark : _borderLight;

  static const Color _hairlineDark = Color(0xFF141B2E);
  static const Color _hairlineLight = Color(0xFFECEFF7);
  static Color get hairline =>
      mode == AppThemeMode.dark ? _hairlineDark : _hairlineLight;

  static const Color _borderStrongDark = Color(0xFF2E3A55);
  static const Color _borderStrongLight = Color(0xFFC8D1E5);
  static Color get borderStrong =>
      mode == AppThemeMode.dark ? _borderStrongDark : _borderStrongLight;

  // ── Text ───────────────────────────────────────────────────
  static const Color _textDark = Color(0xFFF4F6FB);
  static const Color _textLight = Color(0xFF0C1222);
  static Color get text => mode == AppThemeMode.dark ? _textDark : _textLight;

  static const Color _textMutedDark = Color(0xFF9BA7C2);
  static const Color _textMutedLight = Color(0xFF5B6B8C);
  static Color get textMuted =>
      mode == AppThemeMode.dark ? _textMutedDark : _textMutedLight;

  static const Color _textDimDark = Color(0xFF6B7894);
  static const Color _textDimLight = Color(0xFF8A99B8);
  static Color get textDim =>
      mode == AppThemeMode.dark ? _textDimDark : _textDimLight;

  static const Color _textFaintDark = Color(0xFF3E4A63);
  static const Color _textFaintLight = Color(0xFFB4BED6);
  static Color get textFaint =>
      mode == AppThemeMode.dark ? _textFaintDark : _textFaintLight;

  // ── Accent — Gradient Blue signature ─────────────────────────
  // Unified blue system: solid blue for meaning, blue gradient for
  // every selection / hero moment across the app. Violet + pink remain
  // only as ambient aurora tints, never for selection.
  static const Color accent = Color(0xFF2E7CF6);
  static const Color accentSoft = Color(0xFF6BA4FF);
  static const Color accentDim = Color(0xFF1D5CFF);
  static const Color accentHover = Color(0xFF4A90FF);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentBlue = Color(0xFF2E7CF6);
  static const Color accentBlueDeep = Color(0xFF1D5CFF);
  static const Color accentBlueSoft = Color(0xFF60A5FA);
  static const Color accentPink = Color(0xFFFF5C8A);

  /// Primary selection gradient — gradient blue, used EVERYWHERE:
  /// library current song, tabs, nav pill, buttons, progress, mini-player.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D5CFF), Color(0xFF2E7CF6), Color(0xFF22D3EE)],
  );

  static const LinearGradient accentGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1D5CFF), Color(0xFF2E7CF6), Color(0xFF22D3EE)],
  );

  /// Soft wash for selected row backgrounds (with white text on top).
  static const LinearGradient selectionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D5CFF), Color(0xFF2E7CF6), Color(0xFF0EA5E9)],
  );

  static const LinearGradient selectionGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1D5CFF), Color(0xFF2E7CF6), Color(0xFF22D3EE)],
  );

  /// Subtle blue wash behind selected content in light mode.
  static Color get selectionWash => accent.withValues(alpha: 0.10);
  static Color get selectionWashStrong => accent.withValues(alpha: 0.18);
  static const Color onSelection = Color(0xFFFFFFFF);

  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x14FFFFFF), Color(0x00000000)],
    stops: [0.0, 0.45],
  );

  // Accent tints for backgrounds
  static Color get accentTint => accent.withValues(alpha: 0.12);
  static Color get accentTintStrong => accent.withValues(alpha: 0.18);
  static Color get accentTintSubtle => accent.withValues(alpha: 0.07);

  // ── Status ─────────────────────────────────────────────────
  // Mode-aware: saturated pastels read well on deep space darks, but wash
  // out on paper whites — light mode gets deepened variants for contrast.
  static Color get success => mode == AppThemeMode.dark
      ? const Color(0xFF2DD4BF)
      : const Color(0xFF0D9488);
  static Color get warning => mode == AppThemeMode.dark
      ? const Color(0xFFFFB020)
      : const Color(0xFFB45309);
  static Color get error => mode == AppThemeMode.dark
      ? const Color(0xFFFF4D6A)
      : const Color(0xFFD9264A);

  /// Solid, mode-independent fallbacks (for gradients / skins that never
  /// want to adapt). Prefer the getters above in UI code.
  static const Color successDark = Color(0xFF2DD4BF);
  static const Color warningDark = Color(0xFFFFB020);
  static const Color errorDark = Color(0xFFFF4D6A);

  // ── Category hues ──────────────────────────────────────────
  // Distinct hues for semantic grouping (filter chips, settings sections,
  // quick actions, download states). Never used for selection — selection
  // is always the blue accent system above.
  static const Color hueTeal = Color(0xFF2EC4B6);
  static const Color hueViolet = Color(0xFF6B5BFF);
  static const Color hueOrange = Color(0xFFFF8A3D);
  static const Color hueMagenta = Color(0xFFB24CFF);
  static const Color hueAqua = Color(0xFF4ECDC4);
  static const Color hueCoral = Color(0xFFFF6B9D);

  // ── Convenience ────────────────────────────────────────────
  static Color get accentOnDark => accent;
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color ambientNeutral = Color(0xFF141927);

  static const Color primary = accent;
  static const Color primaryLight = accent;
  static const Color primaryDark = accentSoft;
  static const Color secondary = accentCyan;
  static const Color secondaryLight = accentCyan;
  static const Color tertiary = accentPink;

  // ── Dynamic aurora mesh ────────────────────────────────────
  // Ambient only — never used for selection. Selection is always blue.
  static const Color auroraViolet = Color(0xFF7C5CFF);
  static const Color auroraBlue = Color(0xFF2E7CF6);
  static const Color auroraCyan = Color(0xFF22D3EE);
  static const Color auroraPink = Color(0xFFFF5C8A);

  /// Animated aurora stops for color-shifting backgrounds.
  /// Cycle through these with an AnimationController for living gradients.
  static const List<Color> auroraCycle = [
    Color(0xFF1D5CFF),
    Color(0xFF2E7CF6),
    Color(0xFF0EA5E9),
    Color(0xFF22D3EE),
  ];

  static Color ambientTint = const Color(0xFF141927);
  static Color ambientGlow = const Color(0xFF1E2639);

  // ── Glass ─────────────────────────────────────────────────
  static Color get glassBase => surface;
  static Color get glassHighlight => surfaceHigh;
  static Color get glassBorder => border;
  static Color get glassBorderStrong => borderStrong;

  static Color glassWithTint(Color base) {
    return Color.alphaBlend(ambientTint.withValues(alpha: 0.12), base);
  }

  static Color get glowColor => accent.withValues(alpha: 0.32);

  static Color get shadowColor => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.50)
      : const Color(0xFF0F1D3A).withValues(alpha: 0.10);

  static Color get shadowColorStrong => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.65)
      : const Color(0xFF0F1D3A).withValues(alpha: 0.16);

  static Color get shadowColorSoft => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.28)
      : const Color(0xFF0F1D3A).withValues(alpha: 0.06);

  static Color get premiumSurface {
    if (mode == AppThemeMode.dark) {
      return const Color(0xFF0A0F1C);
    }
    return const Color(0xFFF8FAFF);
  }

  // ── Overlay ────────────────────────────────────────────────
  static Color get overlayScrim => mode == AppThemeMode.dark
      ? Colors.black.withValues(alpha: 0.60)
      : Colors.black.withValues(alpha: 0.28);

  static Color get overlayStrong => mode == AppThemeMode.dark
      ? Colors.black.withValues(alpha: 0.76)
      : Colors.black.withValues(alpha: 0.45);

  // ── Spacing ────────────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;
  static const double s80 = 80;

  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double rFull = 999;

  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durNormal = Duration(milliseconds: 220);
  static const Duration durSlow = Duration(milliseconds: 350);
  static const Duration durPage = Duration(milliseconds: 420);

  static Color get shimmerBase => mode == AppThemeMode.dark
      ? const Color(0xFF101625)
      : const Color(0xFFE8ECF3);
  static Color get shimmerHighlight => mode == AppThemeMode.dark
      ? const Color(0xFF1E2639)
      : const Color(0xFFF2F4F8);

  static const LinearGradient subtleVerticalFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x00000000)],
  );
}

/// Typography — modern, expressive, built for music.
/// Display uses Plus Jakarta Sans ExtraBold with tight tracking;
/// body stays highly legible with relaxed line-height.
class AppTypography {
  AppTypography._();

  static TextTheme build({required bool isDark}) {
    final base = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final tx = GoogleFonts.plusJakartaSansTextTheme(base);
    final text = AppColors.text;
    final muted = AppColors.textMuted;
    final dim = AppColors.textDim;

    TextStyle jakarta({
      required Color color,
      required double size,
      required FontWeight weight,
      double? spacing,
      double? height,
    }) => GoogleFonts.plusJakartaSans(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing ?? -0.2,
      height: height,
    );

    return tx.copyWith(
      displayLarge: jakarta(
        color: text,
        size: 44,
        weight: FontWeight.w800,
        spacing: -1.6,
        height: 1.0,
      ),
      displayMedium: jakarta(
        color: text,
        size: 34,
        weight: FontWeight.w800,
        spacing: -1.0,
        height: 1.05,
      ),
      headlineLarge: jakarta(
        color: text,
        size: 30,
        weight: FontWeight.w800,
        spacing: -0.8,
        height: 1.1,
      ),
      headlineMedium: jakarta(
        color: text,
        size: 26,
        weight: FontWeight.w700,
        spacing: -0.6,
        height: 1.15,
      ),
      titleLarge: jakarta(
        color: text,
        size: 22,
        weight: FontWeight.w700,
        spacing: -0.4,
      ),
      titleMedium: jakarta(
        color: text,
        size: 17,
        weight: FontWeight.w700,
        spacing: -0.2,
      ),
      titleSmall: jakarta(
        color: muted,
        size: 14,
        weight: FontWeight.w600,
        spacing: 0.1,
      ),
      bodyLarge: jakarta(
        color: text,
        size: 16,
        weight: FontWeight.w500,
        spacing: -0.1,
        height: 1.45,
      ),
      bodyMedium: jakarta(
        color: muted,
        size: 14,
        weight: FontWeight.w500,
        spacing: -0.1,
        height: 1.5,
      ),
      bodySmall: jakarta(
        color: dim,
        size: 12.5,
        weight: FontWeight.w500,
        height: 1.4,
      ),
      labelLarge: jakarta(
        color: text,
        size: 14,
        weight: FontWeight.w700,
        spacing: 0.1,
      ),
      labelMedium: jakarta(
        color: muted,
        size: 12.5,
        weight: FontWeight.w600,
        spacing: 0.2,
      ),
      labelSmall: jakarta(
        color: dim,
        size: 11,
        weight: FontWeight.w700,
        spacing: 0.8,
      ),
    );
  }
}

class AppTheme {
  static ThemeData themeFor(AppThemeMode mode) {
    AppColors.mode = mode;
    final isDark = mode == AppThemeMode.dark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.accentCyan,
            onSecondary: const Color(0xFF06070C),
            tertiary: AppColors.accentPink,
            onTertiary: AppColors.onAccent,
            surface: AppColors.surface,
            onSurface: AppColors.text,
            error: AppColors.error,
            onError: AppColors.text,
            outline: AppColors.border,
            surfaceContainerHighest: AppColors.surfaceHigh,
            surfaceContainer: AppColors.card,
            onSurfaceVariant: AppColors.textMuted,
          )
        : ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.accentBlue,
            onSecondary: AppColors.onAccent,
            tertiary: AppColors.accentPink,
            onTertiary: AppColors.onAccent,
            surface: AppColors.surface,
            onSurface: AppColors.text,
            error: AppColors.error,
            onError: Colors.white,
            outline: AppColors.border,
            surfaceContainerHighest: AppColors.surfaceHigh,
            surfaceContainer: AppColors.card,
            onSurfaceVariant: AppColors.textMuted,
          );

    // Complete the Material 3 container roles so any widget that reaches
    // for scheme containers (chips, menus, FABs, system dialogs) lands on
    // the Nexora palette instead of default Material tones.
    final colorSchemeCompleted = colorScheme.copyWith(
      surfaceDim: AppColors.background,
      surfaceBright: AppColors.surface,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceRaised,
      surfaceContainerHigh: AppColors.surfaceHigh,
      outlineVariant: AppColors.hairline,
      primaryContainer: AppColors.accentTint,
      onPrimaryContainer: isDark ? AppColors.accentSoft : AppColors.accentDim,
      secondaryContainer: AppColors.accentCyan.withValues(alpha: 0.12),
      onSecondaryContainer: isDark
          ? AppColors.accentCyan
          : const Color(0xFF0E7490),
      tertiaryContainer: AppColors.accentPink.withValues(alpha: 0.12),
      onTertiaryContainer: isDark
          ? AppColors.accentPink
          : const Color(0xFFC81E5A),
      errorContainer: AppColors.error.withValues(alpha: 0.12),
      onErrorContainer: AppColors.error,
    );

    final textTheme = AppTypography.build(isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      colorScheme: colorSchemeCompleted,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: AppColors.text, size: 22),
      primaryIconTheme: IconThemeData(color: AppColors.accent, size: 22),
      dividerTheme: DividerThemeData(
        color: AppColors.hairline,
        thickness: 0.6,
        space: 0.6,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.background,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.background,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: textTheme.headlineMedium,
        centerTitle: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadowColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.96),
        contentTextStyle: TextStyle(color: AppColors.text, fontSize: 14),
        actionTextColor: AppColors.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 0.7),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 12,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: AppColors.shadowColorStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 0.7),
        ),
        textStyle: TextStyle(color: AppColors.text, fontSize: 14),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.7),
        ),
        textStyle: TextStyle(color: AppColors.text, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textDim,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border, width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        side: BorderSide(color: AppColors.border, width: 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        labelStyle: TextStyle(color: AppColors.text, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceHigh,
        thumbColor: AppColors.text,
        overlayColor: AppColors.accent.withValues(alpha: 0.16),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceHigh,
        circularTrackColor: AppColors.surfaceHigh,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accentTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.surfaceHigh;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.text,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.hairline,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.surfaceHigh.withValues(alpha: 0.4),
    );
  }

  static ThemeData get darkTheme => themeFor(AppThemeMode.dark);

  static ThemeData get lightTheme => themeFor(AppThemeMode.light);
}
