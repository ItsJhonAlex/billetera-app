// Conversión entre monedas con tasas manuales. Lógica pura, testeable.
//
// Las tasas se pasan en un mapa `"FROM>TO" -> rate`, donde `1 FROM = rate TO`.

/// Clave de una tasa dirigida.
String rateKey(String from, String to) => '$from>$to';

/// Resuelve la tasa `1 from = ? to`:
/// 1) par directo, 2) inverso (÷), 3) puente por [defaultCode]. `null` si nada.
double? resolveRate(
  String from,
  String to,
  Map<String, double> rates,
  String defaultCode,
) {
  if (from == to) return 1;
  final direct = rates[rateKey(from, to)];
  if (direct != null && direct > 0) return direct;
  final inverse = rates[rateKey(to, from)];
  if (inverse != null && inverse > 0) return 1 / inverse;
  // Puente por la predeterminada (solo si ninguna de las dos es la default).
  if (from != defaultCode && to != defaultCode) {
    final a = resolveRate(from, defaultCode, rates, defaultCode);
    final b = resolveRate(defaultCode, to, rates, defaultCode);
    if (a != null && b != null) return a * b;
  }
  return null;
}

/// Convierte un importe en centavos de [from] a [to]. `null` si no hay tasa.
/// Asume 2 decimales en ambas monedas.
int? convertMinor(
  int minor,
  String from,
  String to,
  Map<String, double> rates,
  String defaultCode,
) {
  final rate = resolveRate(from, to, rates, defaultCode);
  if (rate == null) return null;
  return (minor * rate).round();
}

/// Importe de una cuenta con su moneda.
typedef MoneyAmount = ({String currency, int minor});

/// Suma de varios importes convertidos a [defaultCode]. Los que no tienen tasa
/// se devuelven en [missing] (códigos de moneda) y no se suman.
({int totalMinor, Set<String> missing}) totalInDefault(
  Iterable<MoneyAmount> amounts,
  Map<String, double> rates,
  String defaultCode,
) {
  var total = 0;
  final missing = <String>{};
  for (final a in amounts) {
    final converted =
        convertMinor(a.minor, a.currency, defaultCode, rates, defaultCode);
    if (converted == null) {
      missing.add(a.currency);
    } else {
      total += converted;
    }
  }
  return (totalMinor: total, missing: missing);
}
