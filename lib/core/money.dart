import 'package:intl/intl.dart';

/// Utilidades para manejar dinero.
///
/// El dinero se guarda y se opera SIEMPRE como un entero en la unidad mínima
/// (centavos). Así evitamos los errores de redondeo de los `double`. La
/// conversión a/desde texto para mostrar al usuario vive aquí.
class Money {
  Money._();

  /// Centavos por unidad de moneda. CUP usa 2 decimales.
  static const int minorPerUnit = 100;

  /// Convierte un importe en centavos a un `double` en unidades (ej. 1550 -> 15.50).
  /// Solo para mostrar; nunca para operar.
  static double toUnits(int minor) => minor / minorPerUnit;

  /// Convierte unidades (ej. 15.5) a centavos redondeando (ej. 1550).
  static int fromUnits(double units) => (units * minorPerUnit).round();

  /// Formatea un importe en centavos para mostrarlo, ej. "$15.50".
  static String format(int minor, {String symbol = r'$', String locale = 'es'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(toUnits(minor));
  }

  /// Parsea lo que el usuario escribe (ej. "15,50" o "15.50") a centavos.
  /// Devuelve `null` si el texto no es un número válido.
  static int? parse(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return fromUnits(value);
  }
}
