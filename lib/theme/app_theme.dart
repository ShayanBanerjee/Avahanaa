/// Avahanaa design tokens.
///
/// Every colour, radius, spacing step and text style in the app resolves from
/// this file. Screens must not hardcode hex values — if a shade is missing,
/// add it here so the whole app moves together.
///
/// See `.claude/skills/avahanaa-design-system` for the governing principles;
/// the tokens below are the code expression of that document.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The two moods every Avahanaa surface belongs to.
///
/// Calm surfaces (onboarding, profile, QR setup) can afford richness.
/// Panic surfaces (an alert arrived, the owner is walking to their car) are
/// oversized, maximum contrast, one unmistakable action.
enum AppMood { calm, panic }

// ---------------------------------------------------------------------------
// Colour
// ---------------------------------------------------------------------------

abstract final class AppColors {
  // Brand ---------------------------------------------------------------
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryDeep = Color(0xFF1E40AF);
  static const Color primaryTint = Color(0xFFEFF6FF);

  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successTint = Color(0xFFECFDF5);

  // Alert — reserved. Red means "an alert" or "this destroys data". Nothing
  // else. Never use it for plain emphasis.
  static const Color alert = Color(0xFFDC2626);
  static const Color alertDeep = Color(0xFFB91C1C);
  static const Color alertDarkest = Color(0xFF7F1D1D);
  static const Color alertTint = Color(0xFFFEE2E2);
  static const Color alertBorder = Color(0xFFFCA5A5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningTint = Color(0xFFFFFBEB);

  // Neutrals ------------------------------------------------------------
  static const Color background = Color(0xFFF9FAFB);
  /// Surface for the delete-account / destructive zone.
  static const Color alertSurface = Color(0xFFFEF2F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F4F6);
  static const Color infoSurface = Color(0xFFF0F9FF);
  /// Hairline that pairs with [infoSurface] — plain [border] disappears on it.
  static const Color infoBorder = Color(0xFFD6ECFB);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xCCFFFFFF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  /// The single brand gradient. Used by the splash, the home hero and the
  /// profile header so the three read as one product.
  static const List<Color> heroGradient = <Color>[
    primary,
    primaryDark,
    success,
  ];

  /// Escalation gradient for panic-mode surfaces.
  static const List<Color> alertGradient = <Color>[alert, alertDeep];
}

// ---------------------------------------------------------------------------
// Shape, spacing, elevation
// ---------------------------------------------------------------------------

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal gutter for scrollable screen content.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
}

abstract final class AppRadius {
  /// Inputs and buttons.
  static const double control = 12;

  /// Cards.
  static const double card = 16;

  /// Hero surfaces and the QR container.
  static const double hero = 24;

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius heroAll = BorderRadius.all(Radius.circular(hero));
}

abstract final class AppShadows {
  /// Cards sit flat on the background with a whisper of lift.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  /// Hero surfaces only — the QR container, the home hero.
  static const List<BoxShadow> hero = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A101828),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  /// A coloured glow, used to make a primary action feel raised.
  static List<BoxShadow> glow(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  /// Entrance curve — decelerating, never bouncy. This is a utility app.
  static const Curve entrance = Curves.easeOutCubic;
  static const Curve emphasis = Curves.easeOutQuart;
}

// ---------------------------------------------------------------------------
// Type
// ---------------------------------------------------------------------------

abstract final class AppFonts {
  /// Headings and numerals with presence.
  static const String display = 'PlusJakartaSans';

  /// Body, labels and anything dense. Inter is the most legible option at
  /// 12–14sp on a phone held at arm's length.
  static const String text = 'Inter';

  /// Kannada, for the printed sticker only. This ships in Bangalore, and the
  /// person standing at the car may not read English. Bundled (rather than
  /// relying on the system font) because a printed artifact must render
  /// identically on every device.
  static const String kannada = 'NotoSansKannada';
}

/// Both font families ship as variable fonts, so weight is applied through the
/// `wght` axis as well as [TextStyle.fontWeight]. Setting only `fontWeight`
/// renders at the default axis position on some Android builds.
List<FontVariation> _wght(FontWeight weight) => <FontVariation>[
  FontVariation('wght', weight.value.toDouble()),
];

TextStyle _display(
  double size,
  FontWeight weight, {
  double? height,
  double letterSpacing = -0.4,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontFamily: AppFonts.display,
    fontSize: size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

TextStyle _text(
  double size,
  FontWeight weight, {
  double? height,
  double letterSpacing = 0,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontFamily: AppFonts.text,
    fontSize: size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

abstract final class AppText {
  // Display — Plus Jakarta Sans -----------------------------------------
  static TextStyle get displayLarge => _display(34, FontWeight.w800, height: 1.15);
  static TextStyle get displayMedium => _display(28, FontWeight.w800, height: 1.2);
  static TextStyle get headlineLarge => _display(24, FontWeight.w700, height: 1.25);
  static TextStyle get headlineMedium => _display(20, FontWeight.w700, height: 1.3);
  static TextStyle get titleLarge => _display(18, FontWeight.w700, height: 1.35);

  // Text — Inter ---------------------------------------------------------
  static TextStyle get titleMedium =>
      _text(16, FontWeight.w600, height: 1.4, letterSpacing: -0.1);
  static TextStyle get titleSmall => _text(15, FontWeight.w600, height: 1.4);
  static TextStyle get bodyLarge => _text(16, FontWeight.w400, height: 1.55);
  static TextStyle get bodyMedium => _text(14, FontWeight.w400, height: 1.55);
  static TextStyle get bodySmall => _text(13, FontWeight.w400, height: 1.5);
  static TextStyle get caption =>
      _text(12, FontWeight.w500, height: 1.4, color: AppColors.textSecondary);

  static TextStyle get labelLarge => _text(15, FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelMedium => _text(13, FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelSmall =>
      _text(11, FontWeight.w700, letterSpacing: 0.5);

  /// An overline for section headers — small, wide, quiet.
  static TextStyle get overline => _text(
    11,
    FontWeight.w700,
    letterSpacing: 1.1,
    color: AppColors.textTertiary,
  );

  /// Numerals that must not jitter as they update (counters, timers).
  static TextStyle get metric => TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    fontVariations: _wght(FontWeight.w800),
    letterSpacing: -0.6,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  /// Registration plates. Always uppercase, letter-spaced, tabular figures so
  /// `1` and `8` occupy the same width.
  static TextStyle get plate => TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontVariations: _wght(FontWeight.w700),
    letterSpacing: 1.2,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  /// Panic-mode headline. The design system floors panic text at 24 — this is
  /// the smallest it may ever be.
  static TextStyle get panicTitle =>
      _display(26, FontWeight.w800, height: 1.2, color: AppColors.onDark);
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

abstract final class AvahanaaTheme {
  /// The app ships light-only on purpose: the QR surfaces, the printable
  /// sticker preview and the panic-mode alert contrast are all calibrated for
  /// a light ground. A half-finished dark theme would regress them.
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onDark,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.success,
      onSecondary: AppColors.onDark,
      secondaryContainer: AppColors.successTint,
      onSecondaryContainer: AppColors.successDark,
      error: AppColors.alert,
      onError: AppColors.onDark,
      errorContainer: AppColors.alertTint,
      onErrorContainer: AppColors.alertDarkest,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    final textTheme = TextTheme(
      displayLarge: AppText.displayLarge,
      displayMedium: AppText.displayMedium,
      headlineLarge: AppText.headlineLarge,
      headlineMedium: AppText.headlineMedium,
      headlineSmall: AppText.titleLarge,
      titleLarge: AppText.titleLarge,
      titleMedium: AppText.titleMedium,
      titleSmall: AppText.titleSmall,
      bodyLarge: AppText.bodyLarge,
      bodyMedium: AppText.bodyMedium,
      bodySmall: AppText.bodySmall,
      labelLarge: AppText.labelLarge,
      labelMedium: AppText.labelMedium,
      labelSmall: AppText.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.text,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x14101828),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: AppText.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          disabledBackgroundColor: AppColors.borderStrong,
          disabledForegroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
          elevation: 0,
          minimumSize: const Size(0, 52),
          textStyle: AppText.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.primary, width: 1.6),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
          minimumSize: const Size(0, 52),
          textStyle: AppText.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppText.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary),
        errorBorder: _inputBorder(AppColors.alert),
        focusedErrorBorder: _inputBorder(AppColors.alert),
        disabledBorder: _inputBorder(AppColors.surfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppText.labelMedium.copyWith(
          color: AppColors.primary,
        ),
        hintStyle: AppText.bodyMedium.copyWith(color: AppColors.textTertiary),
        errorStyle: AppText.bodySmall.copyWith(color: AppColors.alert),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.heroAll),
        titleTextStyle: AppText.headlineMedium,
        contentTextStyle: AppText.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppText.bodyMedium.copyWith(color: AppColors.onDark),
        actionTextColor: AppColors.surface,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: AppText.titleSmall,
        subtitleTextStyle: AppText.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        iconColor: AppColors.textSecondary,
        minVerticalPadding: AppSpacing.md,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.border;
          }
          return states.contains(WidgetState.selected)
              ? AppColors.success
              : AppColors.borderStrong;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: const Color(0x1A101828),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        textStyle: AppText.bodyMedium,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppText.labelSmall.copyWith(letterSpacing: 0.2),
        unselectedLabelStyle: AppText.labelSmall.copyWith(
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: AppText.bodySmall.copyWith(color: AppColors.onDark),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: AppRadius.controlAll,
      borderSide: BorderSide(color: color, width: 1.6),
    );
  }
}
