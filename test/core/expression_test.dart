import 'package:billetera/core/expression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateExpression', () {
    test('número suelto', () {
      expect(evaluateExpression('200'), 200);
      expect(evaluateExpression('  15.5 '), 15.5);
    });

    test('coma como separador decimal', () {
      expect(evaluateExpression('15,50'), 15.5);
      expect(evaluateExpression('200,5 + 3'), 203.5);
    });

    test('sumas y restas encadenadas', () {
      expect(evaluateExpression('200 + 200 + 300'), 700);
      expect(evaluateExpression('500 - 100 - 50'), 350);
    });

    test('multiplicación y división', () {
      expect(evaluateExpression('300 * 4'), 1200);
      expect(evaluateExpression('100 / 2'), 50);
    });

    test('respeta la precedencia', () {
      expect(evaluateExpression('200 * 20 - 10'), 3990);
      expect(evaluateExpression('300 * 4 + 100'), 1300);
      expect(evaluateExpression('100/2 + 20*2'), 90);
    });

    test('paréntesis cambian la precedencia', () {
      expect(evaluateExpression('(100 + 20) * 2'), 240);
      expect(evaluateExpression('100 / (2 + 3)'), 20);
    });

    test('signos unarios', () {
      expect(evaluateExpression('-5 + 10'), 5);
      expect(evaluateExpression('-(2 + 3)'), -5);
    });

    test('división por cero es inválida', () {
      expect(evaluateExpression('10 / 0'), isNull);
      expect(evaluateExpression('5 / (3 - 3)'), isNull);
    });

    test('entradas inválidas devuelven null', () {
      expect(evaluateExpression(''), isNull);
      expect(evaluateExpression('   '), isNull);
      expect(evaluateExpression('abc'), isNull);
      expect(evaluateExpression('2 +'), isNull);
      expect(evaluateExpression('2 ** 3'), isNull);
      expect(evaluateExpression('(2 + 3'), isNull);
      expect(evaluateExpression('2 + 3)'), isNull);
      expect(evaluateExpression('2 3'), isNull);
    });
  });
}
