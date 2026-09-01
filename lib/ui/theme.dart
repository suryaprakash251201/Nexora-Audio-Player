import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global theme mode selector. The app sets this before the frame is built so
/// that the whole `AppColors` palette resolves consistently across every screen
/// (the palette is read as runtime getters, so the build tree re-evaluates them
/// whenever the app rebuilds after a toggle).
enum AppThemeMode { dark, light }

/// Theme-aware color palette. Every token is a getter that resolves against
/// the current [AppThemeMode], so flipping the app theme recolor the entire UI
/// without touching hundreds of call sites.
class AppColors {
  AppColors._();

  /// The active theme mode. Set by the app root before building.
  static AppThemeMode mode = AppThemeMode.dark;

  // ── Backgrounds ── (refined: richer midnight for dark, warm paper for light)
  static const Color _backgroundDark = Color(0xFF080810);
  static const Color _backgroundLight = Color(0xFFF7F7FB);
  static Color get background =>
      mode == AppThemeMode.dark ? _backgroundDark : _backgroundLight;

  static const Color _surfaceDark = Color(0xFF12121E);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static Color get surface =>
      mode == AppThemeMode.dark ? _surfaceDark : _surfaceLight;

  static const Color _surfaceRaisedDark = Color(0xFF1A1A2E);
  static const Color _surfaceRaisedLight = Color(0xFFEEF0F7);
  static Color get surfaceRaised =>
      mode == AppThemeMode.dark ? _surfaceRaisedDark : _surfaceRaisedLight;

  static const Color _surfaceHighDark = Color(0xFF24243E);
  static const Color _surfaceHighLight = Color(0xFFE4E8F2);
  static Color get surfaceHigh =>
      mode == AppThemeMode.dark ? _surfaceHighDark : _surfaceHighLight;

  // ── Accent ──
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color tertiary = Color(0xFFF472B6);

  // ── Status ──
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);

  // ── Text ── (improved contrast for light, softer muted for dark)
  static const Color _textDark = Color(0xFFF8F8FF);
  static const Color _textLight = Color(0xFF0F0F1A);
  static Color get text => mode == AppThemeMode.dark ? _textDark : _textLight;

  static const Color _textMutedDark = Color(0xFFA1A1B5);
  static const Color _textMutedLight = Color(0xFF5E5E78);
  static Color get textMuted =>
      mode == AppThemeMode.dark ? _textMutedDark : _textMutedLight;

  static const Color _textDimDark = Color(0xFF73738A);
  static const Color _textDimLight = Color(0xFF8A8AA6);
  static Color get textDim =>
      mode == AppThemeMode.dark ? _textDimDark : _textDimLight;

  // ── Borders & Lines ── (stronger light borders for definition)
  static const Color _borderDark = Color(0xFF23233A);
  static const Color _borderLight = Color(0xFFE3E6F0);
  static Color get border =>
      mode == AppThemeMode.dark ? _borderDark : _borderLight;

  static const Color _hairlineDark = Color(0xFF2E2E4A);
  static const Color _hairlineLight = Color(0xFFEAEAF2);
  static Color get hairline =>
      mode == AppThemeMode.dark ? _hairlineDark : _hairlineLight;

  static const Color _borderLightDark = Color(0xFF3A3A52);
  static const Color _borderLightLight = Color(0xFFC2C6D6);
  static Color get borderLight =>
      mode == AppThemeMode.dark ? _borderLightDark : _borderLightLight;

  // ── Glass ── (premium: slightly more opaque light glass for readability)
  static const Color _glassBaseDark = Color(0xFF1C1C32);
  static const Color _glassBaseLight = Color(0xFFFEFEFF);
  static Color get glassBase =>
      mode == AppThemeMode.dark ? _glassBaseDark : _glassBaseLight;

  static const Color _glassHighlightDark = Color(0x0FFFFFFF);
  static const Color _glassHighlightLight = Color(0x0F000000);
  static Color get glassHighlight =>
      mode == AppThemeMode.dark ? _glassHighlightDark : _glassHighlightLight;

  static const Color _glassBorderDark = Color(0x18FFFFFF);
  static const Color _glassBorderLight = Color(0x1A0F0F1A);
  static Color get glassBorder =>
      mode == AppThemeMode.dark ? _glassBorderDark : _glassBorderLight;

  static const Color _glassBorderStrongDark = Color(0x28FFFFFF);
  static const Color _glassBorderStrongLight = Color(0x2A0F0F1A);
  static Color get glassBorderStrong => mode == AppThemeMode.dark
      ? _glassBorderStrongDark
      : _glassBorderStrongLight;

  // ── Gradients ──
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primary, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get secondaryGradient => const LinearGradient(
    colors: [secondary, Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [primary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get shimmerGradient => const LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x08FFFFFF), Color(0x00FFFFFF)],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  static const LinearGradient darkVignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x40000000), Color(0xB3000000)],
  );
}

class AppTheme {
  /// Build the theme for the given mode after pointing the global palette at it.
  static ThemeData themeFor(AppThemeMode mode) {
    AppColors.mode = mode;
    final isDark = mode == AppThemeMode.dark;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            tertiary: AppColors.tertiary,
            surface: AppColors.surface,
            error: AppColors.error,
            onPrimary: AppColors.text,
            onSecondary: AppColors.text,
            onSurface: AppColors.text,
          )
        : ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            tertiary: AppColors.tertiary,
            surface: AppColors.surface,
            error: AppColors.error,
            onPrimary: AppColors.text,
            onSecondary: AppColors.text,
            onSurface: AppColors.text,
          );

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme:
          GoogleFonts.interTextTheme(
            isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
          ).copyWith(
            // Display / Hero
            displayLarge: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.1,
            ),
            displayMedium: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.15,
            ),
            // Headlines
            headlineLarge: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            headlineMedium: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            // Titles
            titleLarge: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleSmall: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            // Body
            bodyLarge: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            bodyMedium: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            bodySmall: GoogleFonts.inter(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            // Labels
            labelLarge: GoogleFonts.inter(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            labelMedium: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            labelSmall: GoogleFonts.inter(
              color: AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceRaised,
        thumbColor: AppColors.text,
        overlayColor: AppColors.primary.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.text,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: TextStyle(color: AppColors.text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0.5,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get darkTheme => themeFor(AppThemeMode.dark);

  static ThemeData get lightTheme => themeFor(AppThemeMode.light);
}
