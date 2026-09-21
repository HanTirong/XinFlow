import 'package:flutter/material.dart';

/// The fixed palette behind XinFlow's light and dark themes.
///
/// Widgets should prefer [AppThemeTokens] or [ColorScheme] instead of using
/// these values directly. Keeping the palette here makes theme decisions easy
/// to review without coupling feature code to a particular brightness.
abstract final class AppPalette {
  static const lightPage = Color(0xFFF6F8FC);
  static const lightPrimaryCard = Color(0xFFFFFFFF);
  static const lightSecondaryCard = Color(0xFFF1F4FA);
  static const lightTextPrimary = Color(0xFF1B2130);
  static const lightTextSecondary = Color(0xFF646C7A);
  static const lightBrand = Color(0xFF5874C8);

  static const darkPage = Color(0xFF11131A);
  static const darkPrimaryCard = Color(0xFF1B1F29);
  static const darkSecondaryCard = Color(0xFF232833);
  static const darkTextPrimary = Color(0xFFF1F3F8);
  static const darkTextSecondary = Color(0xFFAEB4C2);
  static const darkBrand = Color(0xFF7F97E6);

  static const warning = Color(0xFFC2413A);
}

/// Semantic colors used by XinFlow components in addition to Material roles.
@immutable
final class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.pageBackground,
    required this.primaryCard,
    required this.secondaryCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.brand,
    required this.brandSoft,
    required this.progressTrack,
    required this.categorySurface,
  });

  static const light = AppThemeTokens(
    pageBackground: AppPalette.lightPage,
    primaryCard: AppPalette.lightPrimaryCard,
    secondaryCard: AppPalette.lightSecondaryCard,
    textPrimary: AppPalette.lightTextPrimary,
    textSecondary: AppPalette.lightTextSecondary,
    brand: AppPalette.lightBrand,
    brandSoft: Color(0xFFE8EDFC),
    progressTrack: Color(0xFFDDE3EE),
    categorySurface: AppPalette.lightSecondaryCard,
  );

  static const dark = AppThemeTokens(
    pageBackground: AppPalette.darkPage,
    primaryCard: AppPalette.darkPrimaryCard,
    secondaryCard: AppPalette.darkSecondaryCard,
    textPrimary: AppPalette.darkTextPrimary,
    textSecondary: AppPalette.darkTextSecondary,
    brand: AppPalette.darkBrand,
    brandSoft: Color(0xFF2B3552),
    progressTrack: Color(0xFF343B48),
    categorySurface: AppPalette.darkSecondaryCard,
  );

  final Color pageBackground;
  final Color primaryCard;
  final Color secondaryCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color brand;
  final Color brandSoft;
  final Color progressTrack;
  final Color categorySurface;

  static AppThemeTokens of(BuildContext context) =>
      Theme.of(context).extension<AppThemeTokens>()!;

  @override
  AppThemeTokens copyWith({
    Color? pageBackground,
    Color? primaryCard,
    Color? secondaryCard,
    Color? textPrimary,
    Color? textSecondary,
    Color? brand,
    Color? brandSoft,
    Color? progressTrack,
    Color? categorySurface,
  }) => AppThemeTokens(
    pageBackground: pageBackground ?? this.pageBackground,
    primaryCard: primaryCard ?? this.primaryCard,
    secondaryCard: secondaryCard ?? this.secondaryCard,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    brand: brand ?? this.brand,
    brandSoft: brandSoft ?? this.brandSoft,
    progressTrack: progressTrack ?? this.progressTrack,
    categorySurface: categorySurface ?? this.categorySurface,
  );

  @override
  AppThemeTokens lerp(covariant AppThemeTokens? other, double t) {
    if (other == null) return this;
    return AppThemeTokens(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      primaryCard: Color.lerp(primaryCard, other.primaryCard, t)!,
      secondaryCard: Color.lerp(secondaryCard, other.secondaryCard, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      categorySurface: Color.lerp(categorySurface, other.categorySurface, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData light() =>
      _build(brightness: Brightness.light, tokens: AppThemeTokens.light);

  static ThemeData dark() =>
      _build(brightness: Brightness.dark, tokens: AppThemeTokens.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppThemeTokens tokens,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: tokens.brand,
      brightness: brightness,
    );
    final colorScheme = baseScheme.copyWith(
      primary: tokens.brand,
      onPrimary: isDark ? const Color(0xFF17254C) : Colors.white,
      primaryContainer: tokens.brandSoft,
      onPrimaryContainer: isDark
          ? const Color(0xFFDDE4FF)
          : const Color(0xFF24396F),
      secondary: tokens.textSecondary,
      onSecondary: tokens.primaryCard,
      secondaryContainer: tokens.secondaryCard,
      onSecondaryContainer: tokens.textPrimary,
      surface: tokens.primaryCard,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      surfaceDim: tokens.pageBackground,
      surfaceBright: tokens.primaryCard,
      surfaceContainerLowest: tokens.primaryCard,
      surfaceContainerLow: tokens.primaryCard,
      surfaceContainer: tokens.primaryCard,
      surfaceContainerHigh: tokens.secondaryCard,
      surfaceContainerHighest: tokens.secondaryCard,
      outline: isDark ? const Color(0xFF707888) : const Color(0xFFB9C0CE),
      outlineVariant: isDark
          ? const Color(0xFF343B48)
          : const Color(0xFFDDE3EE),
    );
    final textTheme = const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ).apply(bodyColor: tokens.textPrimary, displayColor: tokens.textPrimary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.pageBackground,
      textTheme: textTheme,
      dividerColor: colorScheme.outlineVariant,
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      cardTheme: CardThemeData(
        color: tokens.primaryCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.primaryCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.primaryCard,
        modalBackgroundColor: tokens.primaryCard,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.primaryCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.brandSoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.brand
                : tokens.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? tokens.brand
                : tokens.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.secondaryCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.brand,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.brand,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: tokens.brand),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.brand,
        linearTrackColor: tokens.progressTrack,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.secondaryCard,
        contentTextStyle: TextStyle(color: tokens.textPrimary),
      ),
    );
  }
}
