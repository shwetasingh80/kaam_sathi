import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing / radius tokens.
class Space {
  Space._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Minimum touch target for primary actions (low-literacy rule: bade button).
  static const tapTarget = 64.0;
}

class Radii {
  Radii._();
  static const s = 12.0;
  static const m = 18.0;
  static const l = 24.0;
  static const xl = 32.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.yellow,
      onPrimary: AppColors.charcoal,
      primaryContainer: AppColors.yellowTint,
      onPrimaryContainer: AppColors.charcoal,
      secondary: AppColors.charcoal,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.charcoalSoft,
      onSecondaryContainer: AppColors.white,
      tertiary: AppColors.orange,
      onTertiary: AppColors.charcoal,
      error: AppColors.red,
      onError: AppColors.white,
      errorContainer: AppColors.redTint,
      onErrorContainer: AppColors.redDark,
      surface: AppColors.cream,
      onSurface: AppColors.charcoal,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.white,
      surfaceContainer: AppColors.white,
      surfaceContainerHigh: AppColors.yellowTint,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1),
      displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
      headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.3),
      titleSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
      bodyLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, height: 1.4),
      bodyMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.4),
      bodySmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35),
      labelLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.2),
      labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      labelSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme.apply(
        bodyColor: AppColors.charcoal,
        displayColor: AppColors.charcoal,
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.m));

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.charcoal,
        ),
        iconTheme: IconThemeData(size: 28, color: AppColors.charcoal),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.l),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.charcoal,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size.fromHeight(Space.tapTarget),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          minimumSize: const Size.fromHeight(Space.tapTarget),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          minimumSize: const Size.fromHeight(Space.tapTarget),
          side: const BorderSide(color: AppColors.charcoal, width: 2),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 20),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.m),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.m),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.m),
          borderSide: const BorderSide(color: AppColors.yellow, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.m),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.yellow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.charcoal,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return const IconThemeData(size: 28, color: AppColors.charcoal);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.l)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
        contentTextStyle: const TextStyle(fontSize: 17, color: AppColors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.m)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.yellow,
        linearTrackColor: AppColors.yellowTint,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.charcoal : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.yellow : AppColors.disabled,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.yellow,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoal),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      ),
    );
  }
}
