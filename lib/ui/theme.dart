import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Active app theme mode. Dark Hi-Fi is the primary experience; light is
/// provided as a calm, paper-toned companion.
enum AppThemeMode { dark, light }

/// Centralized design tokens for the Nexora Hi-Fi redesign.
///
/// The palette is deliberately restrained:
/// - Near-black surfaces
/// - Subtle charcoal layering
/// - A single warm accent (#D8B56A) reserved for meaningful states
///
/// Avoid using accent colors as decorative fills. They communicate:
/// progress, selected tabs, the Hi-Fi badge, and important actions.
class AppColors {
  AppColors._();

  static AppThemeMode mode = AppThemeMode.dark;

  // ── Backgrounds ─────────────────────────────────────────────
  // Mode-aware getters: they resolve to the matching light/dark palette at
  // runtime so that `AppColors.xxx` always reflects the currently active
  // theme. Do NOT mark these `const` — that would freeze them to the dark
  // palette and make Theme switching appear broken.
  // Blue-black audiophile palette — deep navy studio vibe, not pure black.
  static const Color _backgroundDark = Color(0xFF070A12);
  static const Color _backgroundLight = Color(0xFFF0F3F8);
  static Color get background =>
      mode == AppThemeMode.dark ? _backgroundDark : _backgroundLight;

  static const Color _surfaceDark = Color(0xFF0F141E);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static Color get surface =>
      mode == AppThemeMode.dark ? _surfaceDark : _surfaceLight;

  static const Color _surfaceRaisedDark = Color(0xFF141E2E);
  static const Color _surfaceRaisedLight = Color(0xFFE8EEF6);
  static Color get surfaceRaised =>
      mode == AppThemeMode.dark ? _surfaceRaisedDark : _surfaceRaisedLight;

  static const Color _surfaceHighDark = Color(0xFF1A2335);
  static const Color _surfaceHighLight = Color(0xFFDDE6F3);
  static Color get surfaceHigh =>
      mode == AppThemeMode.dark ? _surfaceHighDark : _surfaceHighLight;

  // ── Borders ────────────────────────────────────────────────
  static const Color _borderDark = Color(0xFF1E2A3F);
  static const Color _borderLight = Color(0xFFD6DDEA);
  static Color get border =>
      mode == AppThemeMode.dark ? _borderDark : _borderLight;

  static const Color _hairlineDark = Color(0xFF162032);
  static const Color _hairlineLight = Color(0xFFE2E8F2);
  static Color get hairline =>
      mode == AppThemeMode.dark ? _hairlineDark : _hairlineLight;

  // ── Text ───────────────────────────────────────────────────
  static const Color _textDark = Color(0xFFE6EAF0);
  static const Color _textLight = Color(0xFF0F172A);
  static Color get text => mode == AppThemeMode.dark ? _textDark : _textLight;

  static const Color _textMutedDark = Color(0xFF8A9AB8);
  static const Color _textMutedLight = Color(0xFF5A6B8A);
  static Color get textMuted =>
      mode == AppThemeMode.dark ? _textMutedDark : _textMutedLight;

  static const Color _textDimDark = Color(0xFF5B6B8A);
  static const Color _textDimLight = Color(0xFF7A8BA8);
  static Color get textDim =>
      mode == AppThemeMode.dark ? _textDimDark : _textDimLight;

  // ── Accent (use sparingly) ─────────────────────────────────
  // Audiophile studio blue — unique, calm, hardware-inspired.
  static const Color accent = Color(0xFF3A7BFF);
  static const Color accentSoft = Color(0xFF5B94FF);
  static const Color accentDim = Color(0xFF2A5FCC);

  // ── Status ─────────────────────────────────────────────────
  static const Color success = Color(0xFF4ECDC4);
  static const Color warning = Color(0xFF6B9FFF);
  static const Color error = Color(0xFFE84855);

  // ── Convenience getters ────────────────────────────────────
  /// Used for the active player position, EQ active band, selected state.
  static Color get accentOnDark => accent;

  /// Foreground for filled accent buttons.
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Subtle ambient tint derived from artwork (kept neutral — caller can
  /// override with sampled colors). Blue-tinted for new palette.
  static const Color ambientNeutral = Color(0xFF141E2E);

  // ── Legacy aliases (for components that still reference these) ──
  // Kept so the redesign doesn't break call sites; never use these for new
  // code — prefer [accent], [text], [textMuted], [border], [surface*].
  static const Color primary = accent;
  static const Color primaryLight = accent;
  static const Color primaryDark = accentSoft;
  static const Color secondary = accent;
  static const Color secondaryLight = accent;
  static const Color tertiary = accent;

  // ── Dynamic Ambient Colors (derived from artwork) ──────────
  static Color ambientTint = const Color(0xFF141E2E);
  static Color ambientGlow = const Color(0xFF1A2335);

  // ── Glassmorphism enhanced ─────────────────────────────────
  static Color get glassBase => surface;
  static Color get glassHighlight => surfaceHigh;
  static Color get glassBorder => border;
  static Color get glassBorderStrong => border;

  /// Enhanced glass with ambient tint support
  static Color glassWithTint(Color base) {
    return Color.alphaBlend(ambientTint.withValues(alpha: 0.15), base);
  }

  /// Glow color for active elements
  static Color get glowColor => accent.withValues(alpha: 0.3);

  /// Shadow colors for elevated cards
  static Color get shadowColor => mode == AppThemeMode.dark
      ? const Color(0xFF000000).withValues(alpha: 0.4)
      : const Color(0xFF000000).withValues(alpha: 0.1);

  /// Premium surface for featured content
  static Color get premiumSurface {
    if (mode == AppThemeMode.dark) {
      return const Color(0xFF0D1320);
    }
    return const Color(0xFFF8FAFF);
  }

  /// Spacing scale used throughout the app.
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

  /// Shape scale.
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double rFull = 999;

  /// Animation durations
  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durNormal = Duration(milliseconds: 220);
  static const Duration durSlow = Duration(milliseconds: 350);
  static const Duration durPage = Duration(milliseconds: 420);

  /// Shimmer colors for loading skeletons
  static Color get shimmerBase => mode == AppThemeMode.dark
      ? const Color(0xFF0F141E)
      : const Color(0xFFE8EEF6);
  static Color get shimmerHighlight => mode == AppThemeMode.dark
      ? const Color(0xFF1A2335)
      : const Color(0xFFF0F3F8);

  /// Editorially tuned gradients (very subtle, used rarely).
  static const LinearGradient subtleVerticalFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x00000000)],
  );
}

/// Typography ramp. Editorial hierarchy: hero, screen, album, track,
/// metadata, technical. Weight is used intentionally rather than always bold.
class AppTypography {
  AppTypography._();

  static TextTheme build({required bool isDark}) {
    final base = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final tx = GoogleFonts.interTextTheme(base);
    // AppColors.mode is already set to `isDark ? dark : light` by
    // AppTheme.themeFor before this is called, so these getters return the
    // correct light/dark variant.
    final text = AppColors.text;
    final muted = AppColors.textMuted;
    final dim = AppColors.textDim;

    return tx.copyWith(
      // 32–40 — used on hero contexts (album page title, login hero).
      displayLarge: GoogleFonts.inter(
        color: text,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.inter(
        color: text,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      // 26–30 — screen titles (Home, Library).
      headlineLarge: GoogleFonts.inter(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.inter(
        color: text,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      // 22–26 — album titles on detail pages.
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
      // 15–17 — track titles.
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
      // 12–14 — secondary information.
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
      // 11–12 — technical / metadata.
      labelSmall: GoogleFonts.inter(
        color: dim,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// App theme factory. Builds the ThemeData for a given mode and points
/// [AppColors.mode] at it so every screen reads the matching palette.
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
            onError: AppColors.text,
            outline: AppColors.border,
            surfaceContainerHighest: AppColors.surfaceHigh,
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
        thickness: 0.5,
        space: 0.5,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.85),
        contentTextStyle: TextStyle(color: AppColors.text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
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
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border, width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border, width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accent, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textDim,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
          side: BorderSide(color: AppColors.border, width: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceHigh,
        thumbColor: AppColors.text,
        overlayColor: AppColors.accent.withValues(alpha: 0.18),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceHigh,
        circularTrackColor: AppColors.surfaceHigh,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.text,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.surfaceHigh.withValues(alpha: 0.5),
    );
  }

  static ThemeData get darkTheme => themeFor(AppThemeMode.dark);

  static ThemeData get lightTheme => themeFor(AppThemeMode.light);
}
