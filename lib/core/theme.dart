import 'package:flutter/material.dart';

/// Tokens de diseño de Billetera (estética "cartera de cuero cosida"), tomados
/// del diseño aprobado. Disponibles para oscuro y claro vía [ThemeExtension];
/// los widgets los leen con `Theme.of(context).tokens`.
@immutable
class BilleteraTokens extends ThemeExtension<BilleteraTokens> {
  const BilleteraTokens({
    required this.bg,
    required this.surfA,
    required this.surfB,
    required this.surf2A,
    required this.surf2B,
    required this.input,
    required this.chip,
    required this.nav,
    required this.leatherA,
    required this.leatherB,
    required this.leatherDeep,
    required this.bd1,
    required this.bd2,
    required this.bd3,
    required this.bdSoft,
    required this.txBright,
    required this.tx1,
    required this.tx2,
    required this.tx3,
    required this.txm,
    required this.txd,
    required this.txf,
    required this.gold,
    required this.goldBright,
    required this.goldSoft,
    required this.goldDeep,
    required this.income,
    required this.expense,
    required this.transfer,
  });

  final Color bg, surfA, surfB, surf2A, surf2B, input, chip, nav;
  final Color leatherA, leatherB, leatherDeep;
  final Color bd1, bd2, bd3, bdSoft;
  final Color txBright, tx1, tx2, tx3, txm, txd, txf;
  final Color gold, goldBright, goldSoft, goldDeep;
  final Color income, expense, transfer;

  /// Degradado de cuero del "hero" de saldo y resúmenes.
  List<Color> get leatherGradient => [leatherA, leatherB, leatherDeep];

  /// Degradado de las tarjetas/superficies.
  List<Color> get surfaceGradient => [surfA, surfB];
  List<Color> get surface2Gradient => [surf2A, surf2B];

  /// Degradado del botón de acción dorado (CTA).
  List<Color> get ctaGradient => [goldBright, gold];

  /// Color del importe según el flujo.
  Color flow({required bool isIncome, bool isTransfer = false}) =>
      isTransfer ? transfer : (isIncome ? income : expense);

  static const dark = BilleteraTokens(
    bg: Color(0xFF1C1714),
    surfA: Color(0xFF2A2320),
    surfB: Color(0xFF221C19),
    surf2A: Color(0xFF2E2622),
    surf2B: Color(0xFF241E1B),
    input: Color(0xFF211B18),
    chip: Color(0xFF1F1A17),
    nav: Color(0xFF1A1512),
    leatherA: Color(0xFF43362C),
    leatherB: Color(0xFF2C2420),
    leatherDeep: Color(0xFF251E1A),
    bd1: Color(0xFF332B26),
    bd2: Color(0xFF3A312B),
    bd3: Color(0xFF4A3B30),
    bdSoft: Color(0xFF352C27),
    txBright: Color(0xFFF4EEE5),
    tx1: Color(0xFFEDE6DD),
    tx2: Color(0xFFC9BCAD),
    tx3: Color(0xFFB6A593),
    txm: Color(0xFF8A7E72),
    txd: Color(0xFF6E6256),
    txf: Color(0xFF5C5147),
    gold: Color(0xFFE0A23B),
    goldBright: Color(0xFFF0C877),
    goldSoft: Color(0xFFE8C98A),
    goldDeep: Color(0xFFC9912F),
    income: Color(0xFF66BB6A),
    expense: Color(0xFFEF5350),
    transfer: Color(0xFF42A5F5),
  );

  static const light = BilleteraTokens(
    bg: Color(0xFFE7DCC7),
    surfA: Color(0xFFF8F1E3),
    surfB: Color(0xFFF1E7D4),
    surf2A: Color(0xFFFFFEFA),
    surf2B: Color(0xFFF6EDDD),
    input: Color(0xFFEFE4D0),
    chip: Color(0xFFE9DEC8),
    nav: Color(0xFFEEE3CE),
    leatherA: Color(0xFFE6D5B7),
    leatherB: Color(0xFFD9C5A2),
    leatherDeep: Color(0xFFCDB892),
    bd1: Color(0xFFE2D3B9),
    bd2: Color(0xFFD8C7A8),
    bd3: Color(0xFFC9B58D),
    bdSoft: Color(0xFFDFCFB3),
    txBright: Color(0xFF2A2018),
    tx1: Color(0xFF382B1C),
    tx2: Color(0xFF5E4C37),
    tx3: Color(0xFF6F5C44),
    txm: Color(0xFF8B7857),
    txd: Color(0xFFA48C69),
    txf: Color(0xFFBCA681),
    gold: Color(0xFFA6741A),
    goldBright: Color(0xFF936913),
    goldSoft: Color(0xFF8A6214),
    goldDeep: Color(0xFF946514),
    income: Color(0xFF3E9E59),
    expense: Color(0xFFC9514E),
    transfer: Color(0xFF2E7CC4),
  );

  @override
  BilleteraTokens copyWith() => this;

  @override
  BilleteraTokens lerp(ThemeExtension<BilleteraTokens>? other, double t) {
    if (other is! BilleteraTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return BilleteraTokens(
      bg: c(bg, other.bg),
      surfA: c(surfA, other.surfA),
      surfB: c(surfB, other.surfB),
      surf2A: c(surf2A, other.surf2A),
      surf2B: c(surf2B, other.surf2B),
      input: c(input, other.input),
      chip: c(chip, other.chip),
      nav: c(nav, other.nav),
      leatherA: c(leatherA, other.leatherA),
      leatherB: c(leatherB, other.leatherB),
      leatherDeep: c(leatherDeep, other.leatherDeep),
      bd1: c(bd1, other.bd1),
      bd2: c(bd2, other.bd2),
      bd3: c(bd3, other.bd3),
      bdSoft: c(bdSoft, other.bdSoft),
      txBright: c(txBright, other.txBright),
      tx1: c(tx1, other.tx1),
      tx2: c(tx2, other.tx2),
      tx3: c(tx3, other.tx3),
      txm: c(txm, other.txm),
      txd: c(txd, other.txd),
      txf: c(txf, other.txf),
      gold: c(gold, other.gold),
      goldBright: c(goldBright, other.goldBright),
      goldSoft: c(goldSoft, other.goldSoft),
      goldDeep: c(goldDeep, other.goldDeep),
      income: c(income, other.income),
      expense: c(expense, other.expense),
      transfer: c(transfer, other.transfer),
    );
  }
}

/// Acceso corto a los tokens desde un [BuildContext].
extension BilleteraThemeX on BuildContext {
  BilleteraTokens get tokens => Theme.of(this).extension<BilleteraTokens>()!;
}

/// Tema visual de Billetera. Construye el tema oscuro y el claro a partir de
/// los [BilleteraTokens]. Fuentes: Hanken Grotesk (texto), Space Grotesk
/// (cifras), Spectral (títulos serif).
class BilleteraTheme {
  BilleteraTheme._();

  // ---- Compatibilidad: constantes usadas por la app (paleta oscura). ----
  static const Color leatherDark = Color(0xFF1C1714);
  static const Color leather = Color(0xFF2A2320);
  static const Color leatherLight = Color(0xFF3A312B);
  static const Color stitch = Color(0xFFE0A23B);
  static const Color stitchSoft = Color(0xFFC9912F);
  static const Color income = Color(0xFF66BB6A);
  static const Color expense = Color(0xFFEF5350);
  static const Color transfer = Color(0xFF42A5F5);

  static Color colorForFlow({required bool isIncome, bool isTransfer = false}) {
    if (isTransfer) return transfer;
    return isIncome ? income : expense;
  }

  /// Familias tipográficas.
  static const String bodyFont = 'Hanken Grotesk';
  static const String numberFont = 'Space Grotesk';
  static const String displayFont = 'Spectral';

  static ThemeData dark() => _build(BilleteraTokens.dark, Brightness.dark);
  static ThemeData light() => _build(BilleteraTokens.light, Brightness.light);

  static ThemeData _build(BilleteraTokens t, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.gold,
      onPrimary: t.bg,
      secondary: t.goldDeep,
      onSecondary: t.bg,
      surface: t.surfA,
      onSurface: t.tx1,
      error: t.expense,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      fontFamily: bodyFont,
      extensions: [t],
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.tx1,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: displayFont,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: t.tx1,
        ),
      ),
      cardTheme: CardThemeData(
        color: t.surfA,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: t.bd1, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.gold,
        foregroundColor: t.bg,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.input,
        hintStyle: TextStyle(color: t.txm),
        labelStyle: TextStyle(color: t.txm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.bd1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.bd1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.gold, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: t.gold),
      dividerTheme: DividerThemeData(color: t.bd1, thickness: 1),
      chipTheme: ChipThemeData(backgroundColor: t.chip),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.nav,
        selectedItemColor: t.gold,
        unselectedItemColor: t.txm,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfA,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surfA,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
