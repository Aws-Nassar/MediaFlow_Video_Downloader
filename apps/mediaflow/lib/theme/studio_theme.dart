import 'package:flutter/material.dart';

enum StudioThemeMode { dark, light, oled }

class StudioPalette extends ThemeExtension<StudioPalette> {
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color accentSoft;
  final Color cyan;
  final Color success;
  final Color warning;
  final Color danger;
  final Color dangerSoft;

  const StudioPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentSoft,
    required this.cyan,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dangerSoft,
  });

  static const dark = StudioPalette(
    background: Color(0xFF0B0D12),
    surface: Color(0xFF12151D),
    surfaceRaised: Color(0xFF181C26),
    border: Color(0xFF262C3A),
    text: Color(0xFFF2F4F8),
    textMuted: Color(0xFFA1A9BA),
    textFaint: Color(0xFF6E788C),
    accent: Color(0xFF7C5CFF),
    accentSoft: Color(0xFF2A2350),
    cyan: Color(0xFF22D3EE),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF3A1D24),
  );

  static const oled = StudioPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF08090D),
    surfaceRaised: Color(0xFF11141C),
    border: Color(0xFF202634),
    text: Color(0xFFF7F8FB),
    textMuted: Color(0xFFA1A9BA),
    textFaint: Color(0xFF6E788C),
    accent: Color(0xFF8B6CFF),
    accentSoft: Color(0xFF241E45),
    cyan: Color(0xFF22D3EE),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF3A1D24),
  );

  static const light = StudioPalette(
    background: Color(0xFFF7F8FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0F2F7),
    border: Color(0xFFDDE2EC),
    text: Color(0xFF12151D),
    textMuted: Color(0xFF5C6478),
    textFaint: Color(0xFF8B93A7),
    accent: Color(0xFF6C4CF1),
    accentSoft: Color(0xFFE9E4FF),
    cyan: Color(0xFF0891B2),
    success: Color(0xFF059669),
    warning: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
    dangerSoft: Color(0xFFFEE2E2),
  );

  @override
  StudioPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? accent,
    Color? accentSoft,
    Color? cyan,
    Color? success,
    Color? warning,
    Color? danger,
    Color? dangerSoft,
  }) {
    return StudioPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      cyan: cyan ?? this.cyan,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
    );
  }

  @override
  StudioPalette lerp(covariant StudioPalette? other, double t) {
    if (other == null) return this;
    return StudioPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
    );
  }
}

ThemeData buildStudioTheme(StudioThemeMode mode) {
  final palette = switch (mode) {
    StudioThemeMode.dark => StudioPalette.dark,
    StudioThemeMode.light => StudioPalette.light,
    StudioThemeMode.oled => StudioPalette.oled,
  };
  final brightness = mode == StudioThemeMode.light
      ? Brightness.light
      : Brightness.dark;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
      ).copyWith(
        primary: palette.accent,
        onPrimary: Colors.white,
        secondary: palette.cyan,
        onSecondary: Colors.black,
        surface: palette.surface,
        onSurface: palette.text,
        error: palette.danger,
        onError: Colors.white,
        outline: palette.border,
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    textTheme: base.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: palette.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(color: palette.textMuted),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceRaised,
      hintStyle: TextStyle(color: palette.textFaint),
      labelStyle: TextStyle(color: palette.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.accent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceRaised,
      contentTextStyle: TextStyle(color: palette.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.border,
      circularTrackColor: palette.border,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accentSoft,
      selectedIconTheme: IconThemeData(color: palette.accent),
      unselectedIconTheme: IconThemeData(color: palette.textMuted),
      selectedLabelTextStyle: TextStyle(
        color: palette.accent,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: palette.textMuted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accentSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? palette.accent : palette.textMuted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      textStyle: TextStyle(color: palette.text, fontSize: 12),
    ),
  );
}

extension StudioPaletteContext on BuildContext {
  StudioPalette get palette =>
      Theme.of(this).extension<StudioPalette>() ?? StudioPalette.dark;
}
