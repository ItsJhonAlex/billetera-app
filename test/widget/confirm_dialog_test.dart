import 'package:billetera/presentation/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<bool?> run(WidgetTester t) async {
    bool? result;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await confirmDialog(
                context,
                title: '¿Borrar?',
                message: 'No se puede deshacer.',
                confirmLabel: 'Borrar',
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    return result;
  }

  testWidgets('confirmar devuelve true', (t) async {
    await run(t);
    expect(find.text('¿Borrar?'), findsOneWidget);
    await t.tap(find.text('Borrar'));
    await t.pumpAndSettle();
    // El diálogo se cerró.
    expect(find.text('¿Borrar?'), findsNothing);
  });

  testWidgets('cancelar cierra el diálogo', (t) async {
    await run(t);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(find.text('¿Borrar?'), findsNothing);
  });
}
