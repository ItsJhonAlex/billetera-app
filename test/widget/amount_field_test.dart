import 'package:billetera/presentation/widgets/amount_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(TextEditingController c) {
  return MaterialApp(
    home: Scaffold(
      body: AmountField(controller: c, label: 'Importe', requirePositive: true),
    ),
  );
}

void main() {
  testWidgets('muestra la vista previa al escribir una operación', (t) async {
    final c = TextEditingController();
    await t.pumpWidget(_host(c));

    await t.enterText(find.byType(TextFormField), '200*3');
    await t.pump();

    // "= $600.00" / "= $600,00" según locale: basta con el total.
    expect(find.textContaining('600'), findsOneWidget);
  });

  testWidgets('no muestra vista previa con un número suelto', (t) async {
    final c = TextEditingController();
    await t.pumpWidget(_host(c));

    await t.enterText(find.byType(TextFormField), '200');
    await t.pump();

    expect(find.textContaining('='), findsNothing);
  });

  testWidgets('marca expresión inválida', (t) async {
    final c = TextEditingController();
    await t.pumpWidget(_host(c));

    await t.enterText(find.byType(TextFormField), '2+');
    await t.pump();

    expect(find.text('Expresión no válida'), findsOneWidget);
  });

  testWidgets('el botón de operaciones muestra/oculta la barra', (t) async {
    final c = TextEditingController();
    await t.pumpWidget(_host(c));

    // Oculta por defecto.
    expect(find.text('×'), findsNothing);

    await t.tap(find.byIcon(Icons.calculate_outlined));
    await t.pump();

    expect(find.text('×'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
  });

  testWidgets('insertar un operador respeta el cursor', (t) async {
    final c = TextEditingController(text: '200');
    await t.pumpWidget(_host(c));

    await t.tap(find.byIcon(Icons.calculate_outlined));
    await t.pump();
    await t.tap(find.text('+'));
    await t.pump();

    expect(c.text, '200+');
  });
}
