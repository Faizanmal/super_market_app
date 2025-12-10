import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Application Theme Configuration
/// Provides comprehensive theming for light and dark modes.
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ==================== Typography ====================
  static const String fontFamily = 'Roboto';
  static const String fontFamilyMonospace = 'RobotoMono';

  // ==================== Spacing ====================
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ==================== Border Radius ====================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ==================== Elevation ====================
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // ==================== Light Theme ====================
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnSecondary,
      secondaryContainer: AppColors.secondaryLight,
      tertiary: AppColors.accent,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.neutral400,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: elevationSm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: elevationSm,
        shadowColor: AppColors.neutral900.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: spacingSm),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: elevationSm,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: elevationMd,
        hoverElevation: elevationLg,
        focusElevation: elevationLg,
        highlightElevation: elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: AppColors.neutral300.withValues(alpha: 0.5)),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: AppColors.textHint,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral100,
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.neutral200,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingXs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.neutral500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
        ),
      ),
      
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.2),
        elevation: elevationMd,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            color: AppColors.neutral600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.neutral600, size: 24);
        }),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral800,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationMd,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: spacingMd,
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        minLeadingWidth: 24,
        horizontalTitleGap: spacingMd,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.neutral200,
        circularTrackColor: AppColors.neutral200,
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.neutral500;
        }),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.neutral300;
        }),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.neutral700,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      
      // Text Theme
      textTheme: _textTheme,
    );
  }

  // ==================== Dark Theme ====================
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.neutral900,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.neutral900,
      tertiary: AppColors.accentLight,
      error: AppColors.errorLight,
      onError: AppColors.neutral900,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.neutral700,
      outline: AppColors.neutral600,
    );

    return lightTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      cardTheme: lightTheme.cardTheme.copyWith(
        color: AppColors.cardDark,
      ),
      
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.neutral700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.neutral700),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        hintStyle: const TextStyle(color: AppColors.textHintDark),
      ),
      
      dialogTheme: lightTheme.dialogTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: AppColors.textSecondaryDark,
        ),
      ),
      
      bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
      ),
      
      navigationBarTheme: lightTheme.navigationBarTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: spacingMd,
      ),
      
      listTileTheme: lightTheme.listTileTheme.copyWith(
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
      ),
    );
  }

  // ==================== Text Theme ====================
  static const TextTheme _textTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    
    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    
    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    
    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    
    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}
