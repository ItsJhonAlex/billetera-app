import 'package:billetera/domain/exchange.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1 USD = 680 CUP, 1 EUR = 800 CUP. (CUP = predeterminada)
  final rates = {
    rateKey('USD', 'CUP'): 680.0,
    rateKey('EUR', 'CUP'): 800.0,
  };

  group('resolveRate', () {
    test('misma moneda = 1', () {
      expect(resolveRate('CUP', 'CUP', rates, 'CUP'), 1);
    });

    test('par directo', () {
      expect(resolveRate('USD', 'CUP', rates, 'CUP'), 680);
    });

    test('inverso', () {
      expect(resolveRate('CUP', 'USD', rates, 'CUP'), closeTo(1 / 680, 1e-9));
    });

    test('puente por la predeterminada (USD->EUR via CUP)', () {
      // 1 USD = 680 CUP; 1 CUP = 1/800 EUR -> 680/800 = 0.85 EUR
      expect(resolveRate('USD', 'EUR', rates, 'CUP'), closeTo(0.85, 1e-9));
    });

    test('par directo explícito gana sobre el puente', () {
      final r = {...rates, rateKey('EUR', 'USD'): 1.2};
      expect(resolveRate('EUR', 'USD', r, 'CUP'), 1.2);
    });

    test('sin tasa devuelve null', () {
      expect(resolveRate('USD', 'JPY', rates, 'CUP'), isNull);
    });
  });

  group('convertMinor', () {
    test('convierte centavos con la tasa', () {
      // 100.00 USD -> 68000.00 CUP
      expect(convertMinor(10000, 'USD', 'CUP', rates, 'CUP'), 6800000);
    });
    test('sin tasa devuelve null', () {
      expect(convertMinor(10000, 'USD', 'JPY', rates, 'CUP'), isNull);
    });
  });

  group('totalInDefault', () {
    test('suma convirtiendo y reporta faltantes', () {
      final result = totalInDefault(
        [
          (currency: 'CUP', minor: 100000), // 1000 CUP
          (currency: 'USD', minor: 10000), // 100 USD -> 68000 CUP = 6800000
          (currency: 'JPY', minor: 5000), // sin tasa
        ],
        rates,
        'CUP',
      );
      expect(result.totalMinor, 100000 + 6800000);
      expect(result.missing, {'JPY'});
    });
  });
}
