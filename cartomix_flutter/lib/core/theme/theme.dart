import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

export 'colors.dart';
export 'gradients.dart';
export 'typography.dart';
export 'spacing.dart';

/// CartoMix theme configuration
/// Pro-first dark mode design for DJ software
class CartoMixTheme {
  CartoMixTheme._();

  /// Dark theme (default, pro-first)
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Scaffold
      scaffoldBackgroundColor: CartoMixColors.bgPrimary,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        surface: CartoMixColors.bgPrimary,
        primary: CartoMixColors.primary,
        secondary: CartoMixColors.accent,
        tertiary: CartoMixColors.success,
        error: CartoMixColors.error,
        onSurface: CartoMixColors.textPrimary,
        onPrimary: Colors.white,
        outline: CartoMixColors.border,
      ),

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: CartoMixColors.bgPrimary,
        foregroundColor: CartoMixColors.textPrimary,
        elevation: 0,
        titleTextStyle: CartoMixTypography.headline,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: CartoMixColors.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg),
          side: const BorderSide(color: CartoMixColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CartoMixColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.lg,
            vertical: CartoMixSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          ),
          textStyle: CartoMixTypography.badge,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CartoMixColors.textSecondary,
          side: const BorderSide(color: CartoMixColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.md,
            vertical: CartoMixSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          ),
          textStyle: CartoMixTypography.badge,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CartoMixColors.primary,
          textStyle: CartoMixTypography.badge,
        ),
      ),

      // Icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: CartoMixColors.textSecondary,
          hoverColor: CartoMixColors.bgHover,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CartoMixColors.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          borderSide: const BorderSide(color: CartoMixColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          borderSide: const BorderSide(color: CartoMixColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          borderSide: const BorderSide(color: CartoMixColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CartoMixSpacing.md,
          vertical: CartoMixSpacing.sm,
        ),
        hintStyle: CartoMixTypography.bodySmall.copyWith(
          color: CartoMixColors.textMuted,
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: CartoMixColors.primary,
        inactiveTrackColor: CartoMixColors.bgTertiary,
        thumbColor: CartoMixColors.primary,
        overlayColor: CartoMixColors.primary.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CartoMixColors.primary;
          }
          return CartoMixColors.bgTertiary;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: CartoMixColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CartoMixColors.primary;
          }
          return CartoMixColors.bgTertiary;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Dropdown
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CartoMixColors.bgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
            borderSide: const BorderSide(color: CartoMixColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.md,
            vertical: CartoMixSpacing.xs,
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(CartoMixColors.bgSecondary),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              side: const BorderSide(color: CartoMixColors.border),
            ),
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: CartoMixColors.border,
        thickness: 1,
        space: 1,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CartoMixColors.bgElevated,
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
          border: Border.all(color: CartoMixColors.border),
        ),
        textStyle: CartoMixTypography.caption,
        padding: const EdgeInsets.symmetric(
          horizontal: CartoMixSpacing.sm,
          vertical: CartoMixSpacing.xs,
        ),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CartoMixColors.primary,
        linearTrackColor: CartoMixColors.bgTertiary,
        circularTrackColor: CartoMixColors.bgTertiary,
      ),

      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(CartoMixColors.border),
        radius: const Radius.circular(3),
        thickness: WidgetStateProperty.all(5),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: CartoMixColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg),
          side: const BorderSide(color: CartoMixColors.border),
        ),
        titleTextStyle: CartoMixTypography.headline,
        contentTextStyle: CartoMixTypography.body,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CartoMixColors.bgElevated,
        contentTextStyle: CartoMixTypography.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: CartoMixTypography.largeTitle,
        displayMedium: CartoMixTypography.title,
        headlineSmall: CartoMixTypography.headline,
        bodyLarge: CartoMixTypography.body,
        bodyMedium: CartoMixTypography.bodySmall,
        labelSmall: CartoMixTypography.caption,
      ),
    );
  }

  /// Shadows for elevated components
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ];

  /// Glow shadow for interactive elements
  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];
}
