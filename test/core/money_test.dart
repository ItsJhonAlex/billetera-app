import 'package:billetera/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parse acepta coma o punto decimal', () {
      expect(Money.parse('15.50'), 1550);
      expect(Money.parse('15,50'), 1550);
      expect(Money.parse('  20 '), 2000);
    });

    test('parse rechaza texto no numérico', () {
      expect(Money.parse('abc'), isNull);
      expect(Money.parse(''), isNull);
    });

    test('redondea al centavo más cercano', () {
      expect(Money.fromUnits(15.555), 1556);
      expect(Money.fromUnits(0.001), 0);
    });

    test('toUnits es la inversa de fromUnits', () {
      expect(Money.toUnits(1550), 15.5);
    });

    test('format incluye dos decimales', () {
      expect(Money.format(1550), contains('15'));
      expect(Money.format(1550), contains('50'));
    });
  });
}
