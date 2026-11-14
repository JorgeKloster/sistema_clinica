import 'package:flutter/material.dart';

/// Paleta do sistema: marrom da marca (o mesmo do logotipo), fundos quentes
/// e cores de status usadas na agenda, no atendimento e nos painéis.
class AppColors {
  AppColors._();

  /// Marrom do logotipo.
  static const Color ink = Color(0xFF41372E);
  static const Color inkDark = Color(0xFF2B2420);

  /// Fundo das páginas e dos dias de destaque na agenda.
  static const Color paper = Color(0xFFFAF7F4);
  static const Color sand = Color(0xFFF6F1EC);

  static const Color line = Color(0xFFE2D8CF);
  static const Color lineStrong = Color(0xFFD8CCC1);
  static const Color muted = Color(0xFF6B5E54);

  static const Color accent = Color(0xFF00796B);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFC77700);
  static const Color info = Color(0xFF1565C0);
  static const Color danger = Color(0xFF9E2A2B);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: Colors.white,
      onSurface: AppColors.inkDark,
      error: AppColors.danger,
      outline: AppColors.lineStrong,
      outlineVariant: AppColors.line,
      surfaceTint: Colors.transparent,
    );

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: Colors.white,
      dividerColor: AppColors.line,
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: AppColors.inkDark,
        displayColor: AppColors.inkDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border(AppColors.lineStrong),
        enabledBorder: border(AppColors.lineStrong),
        focusedBorder: border(AppColors.ink, 1.5),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.5),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: Color(0xFF9A8E84)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          shape: buttonShape,
          padding: buttonPadding,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: buttonShape,
          padding: buttonPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.lineStrong),
          shape: buttonShape,
          padding: buttonPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sand,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(color: AppColors.inkDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: AppColors.inkDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inkDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.ink,
        selectedColor: AppColors.ink,
        selectedTileColor: AppColors.sand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        iconColor: AppColors.ink,
        collapsedIconColor: AppColors.ink,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
      ),
    );
  }
}
