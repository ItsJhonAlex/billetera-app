import 'package:flutter/material.dart';

/// Paleta y tema visual de Billetera: estética de cartera de cuero oscuro con
/// acento ámbar/dorado (el "hilo" del cosido).
class BilleteraTheme {
  BilleteraTheme._();

  // Cuero y superficies
  static const Color leatherDark = Color(0xFF1C1714); // fondo, cuero casi negro
  static const Color leather = Color(0xFF2A2320); // tarjetas
  static const Color leatherLight = Color(0xFF3A312B); // bordes/realces
  static const Color stitch = Color(0xFFE0A23B); // ámbar dorado (acento)
  static const Color stitchSoft = Color(0xFFC9912F);

  // Semánticos para movimientos
  static const Color income = Color(0xFF66BB6A);
  static const Color expense = Color(0xFFEF5350);
  static const Color transfer = Color(0xFF42A5F5);

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: stitch,
      onPrimary: leatherDark,
      secondary: stitchSoft,
      onSecondary: leatherDark,
      surface: leather,
      onSurface: Color(0xFFEDE6DD),
      error: expense,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: leatherDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: leatherDark,
        foregroundColor: Color(0xFFEDE6DD),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: leather,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: leatherLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: stitch,
        foregroundColor: leatherDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: leather,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: leatherLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: leatherLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stitch, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(iconColor: stitch),
      dividerTheme: const DividerThemeData(color: leatherLight, thickness: 1),
      chipTheme: const ChipThemeData(backgroundColor: leatherLight),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: leatherDark,
        selectedItemColor: stitch,
        unselectedItemColor: Color(0xFF8A7E72),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Color asociado al tipo de movimiento (para montos, iconos, etc.).
  static Color colorForFlow({required bool isIncome, bool isTransfer = false}) {
    if (isTransfer) return transfer;
    return isIncome ? income : expense;
  }
}
