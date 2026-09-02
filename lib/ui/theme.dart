import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Active app theme mode. Dark is the immersive listening environment;
/// light is an airy, paper-inspired companion with real depth.
enum AppThemeMode { dark, light }

/// Centralized design tokens for Nexora.
/// Palette philosophy: restrained, tactile, built for long listening sessions.
class AppColors {
  AppColors._();

  static AppThemeMode mode = AppThemeMode.dark;

  // ── Backgrounds ─────────────────────────────────────────────
  // Dark: inky studio navy — depth without pure black harshness.
  // Light: cool mist with subtle warmth, cards pop as pure white.
  static const Color _backgroundDark = Color(0xFF080B14);
  static const Color _backgroundLight = Color(0xFFF2F4F8);
  static Color get background =>
      mode == AppThemeMode.dark ? _backgroundDark : _backgroundLight;

  static const Color _surfaceDark = Color(0xFF111827);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static Color get surface =>
      mode == AppThemeMode.dark ? _surfaceDark : _surfaceLight;

  static const Color _surfaceRaisedDark = Color(0xFF172033);
  static const Color _surfaceRaisedLight = Color(0xFFE8ECF3);
  static Color get surfaceRaised =>
      mode == AppThemeMode.dark ? _surfaceRaisedDark : _surfaceRaisedLight;

  static const Color _surfaceHighDark = Color(0xFF1E2D4A);
  static const Color _surfaceHighLight = Color(0xFFDDE3F0);
  static Color get surfaceHigh =>
      mode == AppThemeMode.dark ? _surfaceHighDark : _surfaceHighLight;

  // Card-specific elevation surfaces
  static const Color _cardDark = Color(0xFF131C2E);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static Color get card => mode == AppThemeMode.dark ? _cardDark : _cardLight;

  static const Color _cardElevatedDark = Color(0xFF1A2744);
  static const Color _cardElevatedLight = Color(0xFFFFFFFF);
  static Color get cardElevated =>
      mode == AppThemeMode.dark ? _cardElevatedDark : _cardElevatedLight;

  // ── Borders ────────────────────────────────────────────────
  static const Color _borderDark = Color(0xFF223047);
  static const Color _borderLight = Color(0xFFD8DEEB);
  static Color get border =>
      mode == AppThemeMode.dark ? _borderDark : _borderLight;

  static const Color _hairlineDark = Color(0xFF18233A);
  static const Color _hairlineLight = Color(0xFFE5EAF3);
  static Color get hairline =>
      mode == AppThemeMode.dark ? _hairlineDark : _hairlineLight;

  static const Color _borderStrongDark = Color(0xFF2A3A56);
  static const Color _borderStrongLight = Color(0xFFC5CFE3);
  static Color get borderStrong =>
      mode == AppThemeMode.dark ? _borderStrongDark : _borderStrongLight;

  // ── Text ───────────────────────────────────────────────────
  static const Color _textDark = Color(0xFFE8ECF1);
  static const Color _textLight = Color(0xFF0F1729);
  static Color get text => mode == AppThemeMode.dark ? _textDark : _textLight;

  static const Color _textMutedDark = Color(0xFF8FA0BE);
  static const Color _textMutedLight = Color(0xFF5B6B8E);
  static Color get textMuted =>
      mode == AppThemeMode.dark ? _textMutedDark : _textMutedLight;

  static const Color _textDimDark = Color(0xFF5E6E8C);
  static const Color _textDimLight = Color(0xFF7A8CB0);
  static Color get textDim =>
      mode == AppThemeMode.dark ? _textDimDark : _textDimLight;

  static const Color _textFaintDark = Color(0xFF3E4D6A);
  static const Color _textFaintLight = Color(0xFF9AA9C7);
  static Color get textFaint =>
      mode == AppThemeMode.dark ? _textFaintDark : _textFaintLight;

  // ── Accent ─────────────────────────────────────────────────
  static const Color accent = Color(0xFF3A7BFF);
  static const Color accentSoft = Color(0xFF6B9FFF);
  static const Color accentDim = Color(0xFF2A5FCC);
  static const Color accentHover = Color(0xFF4A8AFF);

  // Accent tints for backgrounds
  static Color get accentTint => accent.withValues(alpha: 0.10);
  static Color get accentTintStrong => accent.withValues(alpha: 0.16);
  static Color get accentTintSubtle => accent.withValues(alpha: 0.06);

  // ── Status ─────────────────────────────────────────────────
  static const Color success = Color(0xFF30C9B0);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFEF4458);

  // ── Convenience ────────────────────────────────────────────
  static Color get accentOnDark => accent;
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color ambientNeutral = Color(0xFF172033);

  static const Color primary = accent;
  static const Color primaryLight = accent;
  static const Color primaryDark = accentSoft;
  static const Color secondary = accent;
  static const Color secondaryLight = accent;
  static const Color tertiary = accent;

  // ── Dynamic ────────────────────────────────────────────────
  static Color ambientTint = const Color(0xFF172033);
  static Color ambientGlow = const Color(0xFF1E2D4A);

  // ── Glass ─────────────────────────────────────────────────
  static Color get glassBase => surface;
  static Color get glassHighlight => surfaceHigh;
  static Color get glassBorder => border;
  static Color get glassBorderStrong => borderStrong;

  static Color glassWithTint(Color base) {
    return Color.alphaBlend(ambientTint.withValues(alpha: 0.12), base);
  }

  static Color get glowColor => accent.withValues(alpha: 0.28);

  static Color get shadowColor => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.45)
      : const Color(0xFF1A2A4A).withValues(alpha: 0.10);

  static Color get shadowColorStrong => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.60)
      : const Color(0xFF1A2A4A).withValues(alpha: 0.16);

  static Color get shadowColorSoft => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.25)
      : const Color(0xFF1A2A4A).withValues(alpha: 0.06);

  static Color get premiumSurface {
    if (mode == AppThemeMode.dark) {
      return const Color(0xFF0E1729);
    }
    return const Color(0xFFF8FAFF);
  }

  // ── Overlay ────────────────────────────────────────────────
  static Color get overlayScrim => mode == AppThemeMode.dark
      ? Colors.black.withValues(alpha: 0.55)
      : Colors.black.withValues(alpha: 0.25);

  static Color get overlayStrong => mode == AppThemeMode.dark
      ? Colors.black.withValues(alpha: 0.72)
      : Colors.black.withValues(alpha: 0.42);

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
      ? const Color(0xFF111827)
      : const Color(0xFFE8ECF3);
  static Color get shimmerHighlight => mode == AppThemeMode.dark
      ? const Color(0xFF1E2D4A)
      : const Color(0xFFF2F4F8);

  static const LinearGradient subtleVerticalFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x00000000)],
  );
}

/// Typography — editorial, calm, deliberately restrained.
class AppTypography {
  AppTypography._();

  static TextTheme build({required bool isDark}) {
    final base = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final tx = GoogleFonts.interTextTheme(base);
    final text = AppColors.text;
    final muted = AppColors.textMuted;
    final dim = AppColors.textDim;

    return tx.copyWith(
      displayLarge: GoogleFonts.inter(
        color: text,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        height: 1.0,
      ),
      displayMedium: GoogleFonts.inter(
        color: text,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.1,
      ),
      headlineLarge: GoogleFonts.inter(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.inter(
        color: text,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      titleLarge: GoogleFonts.inter(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: GoogleFonts.inter(
        color: text,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleSmall: GoogleFonts.inter(
        color: muted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      bodyLarge: GoogleFonts.inter(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.inter(
        color: muted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        color: dim,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.inter(
        color: text,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.inter(
        color: muted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        color: dim,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
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
            secondary: AppColors.accentSoft,
            onSecondary: AppColors.onAccent,
            tertiary: AppColors.accent,
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
            secondary: AppColors.accentSoft,
            onSecondary: AppColors.onAccent,
            tertiary: AppColors.accent,
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

    final textTheme = AppTypography.build(isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      colorScheme: colorScheme,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 0.7),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.92),
        contentTextStyle: TextStyle(color: AppColors.text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 0.7),
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
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border, width: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        side: BorderSide(color: AppColors.border, width: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(color: AppColors.text, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceHigh,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.14),
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
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
