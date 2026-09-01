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

/// One complete set of UI colours.
///
/// Two of these exist — [AvahanaaPalette.light] and [AvahanaaPalette.dark] —
/// and [AppColors] reads whichever is active. Screens keep referring to
/// `AppColors.textPrimary` exactly as before; the indirection lives here so
/// the whole app moves together, which is the rule this file exists to
/// enforce.
///
/// Note what is *not* in here: the brand gradient and the sticker's ink. Those
/// are in [AppPrint], fixed, because they end up on paper. A dark theme that
/// reached the printable sticker would produce a black sheet and an unscannable
/// code.
final class AvahanaaPalette {
  const AvahanaaPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.primaryDeep,
    required this.primaryTint,
    required this.success,
    required this.successDark,
    required this.successTint,
    required this.alert,
    required this.alertDeep,
    required this.alertDarkest,
    required this.alertTint,
    required this.alertBorder,
    required this.alertSurface,
    required this.warning,
    required this.warningTint,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.infoSurface,
    required this.infoBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderStrong,
  });

  final Brightness brightness;

  final Color primary;
  final Color primaryDark;
  final Color primaryDeep;
  final Color primaryTint;

  final Color success;
  final Color successDark;
  final Color successTint;

  final Color alert;
  final Color alertDeep;
  final Color alertDarkest;
  final Color alertTint;
  final Color alertBorder;
  final Color alertSurface;

  final Color warning;
  final Color warningTint;

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color infoSurface;
  final Color infoBorder;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;
  final Color borderStrong;

  bool get isDark => brightness == Brightness.dark;

  /// The daylight palette. Neutrals are blue-tinted slate rather than pure
  /// grey, so they sit with the brand blue instead of reading faintly green
  /// beside it.
  static const AvahanaaPalette light = AvahanaaPalette(
    brightness: Brightness.light,
    primary: Color(0xFF8A5A18),
    primaryDark: Color(0xFF6E4712),
    primaryDeep: Color(0xFF4A2F0B),
    primaryTint: Color(0xFFFDF6EA),
    success: Color(0xFF10B981),
    successDark: Color(0xFF047857),
    successTint: Color(0xFFECFDF5),
    alert: Color(0xFFC81B30),
    alertDeep: Color(0xFFA01625),
    alertDarkest: Color(0xFF6E0F1B),
    alertTint: Color(0xFFFDE7EA),
    alertBorder: Color(0xFFF5A3AD),
    alertSurface: Color(0xFFFEF2F2),
    warning: Color(0xFFC2410C),
    warningTint: Color(0xFFFFF7ED),
    background: Color(0xFFFAF9F7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F2EF),
    infoSurface: Color(0xFFFAF6EF),
    infoBorder: Color(0xFFEADFCB),
    textPrimary: Color(0xFF1A1814),
    textSecondary: Color(0xFF55504A),
    textTertiary: Color(0xFF736C63),
    border: Color(0xFFE6E1DA),
    borderStrong: Color(0xFFCFC8BE),
  );

  /// The night palette.
  ///
  /// Not an inversion. Two things had to change in kind rather than in value:
  ///
  /// The accents are lifted. `#2563EB` gives 2.4:1 on a dark ground and is
  /// unreadable; the blue, green and crimson are all raised in luminance until
  /// they clear AA against both the background and the raised surface. The
  /// crimson in particular becomes a coral — a deep red on near-black is
  /// almost invisible, which is a poor property for the colour that means
  /// "somebody is at your car".
  ///
  /// The grounds are blue-tinted, for the same reason the light neutrals are:
  /// a neutral charcoal beside this blue reads brown.
  ///
  /// Surfaces get *lighter* as they come forward — `background` is the
  /// furthest back — because on a dark theme elevation reads as light, not as
  /// shadow. Shadows are nearly invisible here, so the card tokens lean on
  /// this separation instead.
  static const AvahanaaPalette dark = AvahanaaPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFE8A33D),
    primaryDark: Color(0xFFF0B95F),
    primaryDeep: Color(0xFFF7D49A),
    primaryTint: Color(0xFF2A2118),
    success: Color(0xFF34D399),
    successDark: Color(0xFF6EE7B7),
    successTint: Color(0xFF10281F),
    alert: Color(0xFFFF6B7A),
    alertDeep: Color(0xFFFF8D98),
    alertDarkest: Color(0xFFFFB3BA),
    alertTint: Color(0xFF3A1119),
    alertBorder: Color(0xFF7A2733),
    alertSurface: Color(0xFF2A0F14),
    warning: Color(0xFFFB923C),
    warningTint: Color(0xFF2E1D10),
    background: Color(0xFF121110),
    surface: Color(0xFF1C1A17),
    surfaceMuted: Color(0xFF262320),
    infoSurface: Color(0xFF241F17),
    infoBorder: Color(0xFF3D352A),
    textPrimary: Color(0xFFF5F2EE),
    textSecondary: Color(0xFFB8B0A6),
    textTertiary: Color(0xFF9A9289),
    border: Color(0xFF322E29),
    borderStrong: Color(0xFF4A443D),
  );
}

/// Colours that must never follow the theme, because they end up as ink.
///
/// The printable sticker and the QR code are physical objects. Dark mode is a
/// property of a screen at night; a sheet of A4 does not have one.
abstract final class AppPrint {
  static const Color brandDeep = Color(0xFF1A1E24);

  /// The flat brand gradient for the **printed** sticker.
  ///
  /// On screen the same ramp is rendered as metal (`MetalPalette.brand`), but
  /// print is unforgiving: a five-stop metallic ramp bands and muddies on a
  /// consumer printer, so the sheet keeps the flat three-stop version.
  /// The flat three-stop version of `MetalPalette.brand`.
  ///
  /// Kept in step with it deliberately: the sticker on the windscreen and the
  /// hero in the app are the same object, and a brand that is bright blue on
  /// paper and anodised steel on screen is two brands.
  static const List<Color> heroGradient = <Color>[
    Color(0xFF23282F),
    Color(0xFF1A1E24),
    Color(0xFF3A2E1E),
  ];
}

/// The active design tokens.
///
/// Every member is a getter over [activePalette], so a theme switch moves the
/// entire app at once without 300-odd call sites having to know about it. The
/// palette is swapped immediately before the tree rebuilds — see
/// `ThemeController` — so a frame never renders half in one palette.
abstract final class AppColors {
  static AvahanaaPalette _active = AvahanaaPalette.light;

  /// The palette currently in force.
  static AvahanaaPalette get activePalette => _active;

  /// Swaps the palette. Only `ThemeController` should call this, and only
  /// immediately before rebuilding the app.
  static void usePalette(AvahanaaPalette palette) => _active = palette;

  static bool get isDark => _active.isDark;

  // Brand ---------------------------------------------------------------
  //
  // The blue here is the same blue as `MetalPalette.brand.base`, deliberately.
  // Before this the hero was one blue and every button, link and active nav
  // item was a brighter one — which is the sort of mismatch nobody can name
  // but everybody notices.
  static Color get primary => _active.primary;
  static Color get primaryDark => _active.primaryDark;
  static Color get primaryDeep => _active.primaryDeep;
  static Color get primaryTint => _active.primaryTint;

  static Color get success => _active.success;
  static Color get successDark => _active.successDark;
  static Color get successTint => _active.successTint;

  // Alert — reserved. Red means "an alert" or "this destroys data". Nothing
  // else. Never use it for plain emphasis.
  static Color get alert => _active.alert;
  static Color get alertDeep => _active.alertDeep;
  static Color get alertDarkest => _active.alertDarkest;
  static Color get alertTint => _active.alertTint;
  static Color get alertBorder => _active.alertBorder;

  static Color get warning => _active.warning;
  static Color get warningTint => _active.warningTint;

  // Neutrals ------------------------------------------------------------
  static Color get background => _active.background;

  /// Surface for the delete-account / destructive zone.
  static Color get alertSurface => _active.alertSurface;
  static Color get surface => _active.surface;
  static Color get surfaceMuted => _active.surfaceMuted;
  static Color get infoSurface => _active.infoSurface;

  /// Hairline that pairs with [infoSurface] — plain [border] disappears on it.
  static Color get infoBorder => _active.infoBorder;

  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get textTertiary => _active.textTertiary;

  /// Text on a saturated brand fill. White in both themes: the fills are
  /// contrast-clamped for it, and flipping it per theme would make the alert
  /// banner unreadable in exactly the moment it matters.
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xCCFFFFFF);

  /// Ink for content sitting on a fill that does **not** follow the theme.
  ///
  /// Some surfaces are fixed by what they represent rather than by the theme:
  /// a vehicle's paint swatch is whatever colour the car is, the alert banner
  /// is red because it is an alert, the hero is the brand gradient. Content on
  /// those must be fixed too.
  ///
  /// Getting this wrong is invisible in light mode and glaring in dark: the
  /// car icon sat on a white swatch in `AppColors.textPrimary`, which in the
  /// night palette is near-white, so it disappeared entirely.
  static const Color inkOnLightFill = Color(0xFF0F172A);

  /// The deep red for a light chip sitting on the alert banner.
  static const Color inkOnAlertFill = Color(0xFFA01625);

  static Color get border => _active.border;
  static Color get borderStrong => _active.borderStrong;

  /// Kept for the printed sticker. See [AppPrint.heroGradient].
  static const List<Color> heroGradient = AppPrint.heroGradient;
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
  /// Tightened one step (Aug 2026), alongside the metal treatment.
  ///
  /// 16 and 24 read friendly — consumer, soft, a little generic. A machined
  /// edge is precise, and the corner radius is most of what says which of
  /// those a surface is. The step is small on purpose: the shapes should feel
  /// more deliberate, not different.

  /// Inputs and buttons.
  static const double control = 12;

  /// Cards.
  static const double card = 14;

  /// Hero surfaces and the QR container.
  static const double hero = 20;

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius heroAll = BorderRadius.all(Radius.circular(hero));
}

abstract final class AppShadows {
  /// Cards sit flat on the background with a whisper of lift.
  ///
  /// Two layers, not one. A single soft blur is the classic tell of a flat
  /// card sitting on a page: real objects cast a tight, dark contact shadow
  /// where they meet the surface *and* a wide, faint ambient one. Splitting
  /// them is what separates "container with a drop shadow" from something that
  /// looks like it has thickness — at the same total opacity.
  static const List<BoxShadow> card = <BoxShadow>[
    // Contact — tight and close, defines the edge.
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    // Ambient — wide and faint, gives the lift.
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Hero surfaces only — the QR container, the home hero.
  static const List<BoxShadow> hero = <BoxShadow>[
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 28,
      offset: Offset(0, 12),
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
  // -- Durations ---------------------------------------------------------
  //
  // Four steps, and everything in the app is one of them. Before this there
  // were twenty-two hand-picked millisecond values scattered across the
  // widgets, which is why nothing quite agreed with anything else: two things
  // animating side by side at 300ms and 320ms do not read as deliberate, they
  // read as sloppy.

  /// A state flip the eye should barely register — a chip filling, a switch.
  static const Duration fast = Duration(milliseconds: 180);

  /// The default. Anything entering, leaving, or resizing.
  static const Duration normal = Duration(milliseconds: 320);

  /// A surface arriving, or a sheet settling.
  static const Duration slow = Duration(milliseconds: 520);

  /// Long, ambient movement — the specular sweep, a skeleton shimmer. Not a
  /// response to anything the user did, which is why it may take its time.
  static const Duration ambient = Duration(milliseconds: 1250);

  /// The pause between ambient passes.
  ///
  /// A highlight that never stops stops reading as metal and starts reading as
  /// a loading state. The gap is the part that sells it.
  static const Duration ambientRest = Duration(seconds: 9);

  /// Between consecutive items in a list entrance.
  ///
  /// Small on purpose. A stagger you can count is a stagger that is showing
  /// off; this one only has to stop eight cards arriving as one slab.
  static const Duration stagger = Duration(milliseconds: 40);

  /// How long a staggered run may take in total, however many items there are.
  /// Past this the last card is arriving after the user has started reading.
  static const Duration staggerCap = Duration(milliseconds: 320);

  // -- Curves ------------------------------------------------------------

  /// Entrance — decelerating, never bouncy. This is a utility app.
  static const Curve entrance = Curves.easeOutCubic;

  /// For the one thing on screen that matters more than the rest.
  static const Curve emphasis = Curves.easeOutQuart;

  /// Leaving. Slightly faster out than in, so dismissal feels obedient.
  static const Curve exit = Curves.easeInCubic;

  /// Ambient travel — symmetric, with no visible start or stop.
  static const Curve ambientCurve = Curves.easeInOutSine;

  /// The delay for item [index] in a staggered list, capped by [staggerCap].
  static Duration staggerFor(int index) {
    final ms = stagger.inMilliseconds * index;
    return Duration(
      milliseconds: ms > staggerCap.inMilliseconds
          ? staggerCap.inMilliseconds
          : ms,
    );
  }
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

/// Optical tracking for display type.
///
/// Letter-spacing is not a constant — the larger the type, the tighter it
/// wants to be. Counters and side-bearings scale with the glyph, so a value
/// that looks right at 18sp leaves 34sp looking gappy and amateur, which is
/// exactly what a single `-0.4` across the whole display scale produced.
///
/// The curve below is roughly -0.03em at the top of the scale easing to
/// -0.015em at the bottom. This is the cheapest thing on the list that makes
/// headings look set rather than typed.
double _opticalTracking(double size) {
  if (size >= 32) return -1.0;
  if (size >= 26) return -0.8;
  if (size >= 22) return -0.6;
  if (size >= 19) return -0.45;
  return -0.3;
}

TextStyle _display(
  double size,
  FontWeight weight, {
  double? height,
  double? letterSpacing,
  Color? color,
}) {
  return TextStyle(
    fontFamily: AppFonts.display,
    fontSize: size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    height: height,
    letterSpacing: letterSpacing ?? _opticalTracking(size),
    color: color ?? AppColors.textPrimary,
  );
}

TextStyle _text(
  double size,
  FontWeight weight, {
  double? height,
  double letterSpacing = 0,
  Color? color,
}) {
  return TextStyle(
    fontFamily: AppFonts.text,
    fontSize: size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? AppColors.textPrimary,
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
  /// The daylight theme.
  static ThemeData light() => _build(AvahanaaPalette.light);

  /// The night theme.
  ///
  /// Not an inverted copy — see [AvahanaaPalette.dark] for what had to change
  /// in kind rather than in value. The printable sticker is unaffected in
  /// either theme; it reads [AppPrint].
  static ThemeData dark() => _build(AvahanaaPalette.dark);

  /// Builds a theme from a palette.
  ///
  /// Reads the palette it is handed rather than the ambient [AppColors], so a
  /// theme can be constructed for a palette that is not currently active —
  /// `MaterialApp` wants both themes up front and picks between them itself.
  static ThemeData _build(AvahanaaPalette p) {
    final isDark = p.isDark;
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: isDark ? const Color(0xFF06101F) : AppColors.onDark,
      primaryContainer: p.primaryTint,
      onPrimaryContainer: p.primaryDeep,
      secondary: p.success,
      onSecondary: isDark ? const Color(0xFF06101F) : AppColors.onDark,
      secondaryContainer: p.successTint,
      onSecondaryContainer: p.successDark,
      error: p.alert,
      onError: isDark ? const Color(0xFF2A0F14) : AppColors.onDark,
      errorContainer: p.alertTint,
      onErrorContainer: p.alertDarkest,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
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
      scaffoldBackgroundColor: p.background,
      fontFamily: AppFonts.text,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x14101828),
        centerTitle: false,
        iconTheme: IconThemeData(color: p.textPrimary, size: 22),
        titleTextStyle: AppText.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: AppColors.onDark,
          disabledBackgroundColor: p.borderStrong,
          disabledForegroundColor: p.surface,
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
          foregroundColor: p.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: p.primary, width: 1.6),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
          minimumSize: const Size(0, 52),
          textStyle: AppText.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: AppText.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: _inputBorder(p.border),
        enabledBorder: _inputBorder(p.border),
        focusedBorder: _inputBorder(p.primary),
        errorBorder: _inputBorder(p.alert),
        focusedErrorBorder: _inputBorder(p.alert),
        disabledBorder: _inputBorder(p.surfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppText.bodyMedium.copyWith(color: p.textSecondary),
        floatingLabelStyle: AppText.labelMedium.copyWith(
          color: p.primary,
        ),
        hintStyle: AppText.bodyMedium.copyWith(color: p.textTertiary),
        errorStyle: AppText.bodySmall.copyWith(color: p.alert),
        prefixIconColor: p.textTertiary,
        suffixIconColor: p.textTertiary,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.heroAll),
        titleTextStyle: AppText.headlineMedium,
        contentTextStyle: AppText.bodyMedium.copyWith(
          color: p.textSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: AppText.bodyMedium.copyWith(color: AppColors.onDark),
        actionTextColor: p.surface,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: p.border,
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
          color: p.textSecondary,
        ),
        iconColor: p.textSecondary,
        minVerticalPadding: AppSpacing.md,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return p.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.border;
          }
          return states.contains(WidgetState.selected)
              ? p.success
              : p.borderStrong;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: const Color(0x1A101828),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        textStyle: AppText.bodyMedium,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.border,
        circularTrackColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textTertiary,
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
          color: p.textPrimary,
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
