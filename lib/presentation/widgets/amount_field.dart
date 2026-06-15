import 'package:flutter/material.dart';

import '../../core/money.dart';

/// Campo de importe que acepta expresiones aritméticas (`200*4+100`,
/// `(100+20)*2`, …) y muestra el total calculado en vivo cuando detecta una
/// operación. Incluye una barra de operadores opcional (se muestra/oculta con
/// un botón) porque el teclado numérico de Android no ofrece `+`, `*` ni `/`.
///
/// Centraliza la validación para los formularios de movimiento y de cuenta.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.autofocus = false,
    this.allowEmpty = false,
    this.requirePositive = false,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool autofocus;

  /// Si es `true`, dejar el campo vacío es válido (se interpreta como 0).
  final bool allowEmpty;

  /// Si es `true`, exige que el resultado sea mayor que cero.
  final bool requirePositive;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  /// Caracteres que indican que el usuario está escribiendo una operación
  /// (y no un número suelto), para decidir si mostrar la vista previa.
  static final _operatorPattern = RegExp(r'[+\-*/()]');

  bool _showOperators = false;

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return widget.allowEmpty ? null : 'Escribe un importe';
    final minor = Money.parseExpression(text);
    if (minor == null) return 'Importe no válido';
    if (widget.requirePositive && minor <= 0) return 'Debe ser mayor que cero';
    return null;
  }

  /// Inserta [token] en la posición del cursor (o reemplaza la selección).
  void _insert(String token) {
    final controller = widget.controller;
    final value = controller.value;
    final sel = value.selection;
    final text = value.text;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, token);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixText: r'$ ',
            helperText: widget.helperText,
            // Botón para mostrar/ocultar la barra de operadores.
            suffixIcon: IconButton(
              tooltip: _showOperators ? 'Ocultar operadores' : 'Operaciones',
              icon: Icon(
                _showOperators ? Icons.calculate : Icons.calculate_outlined,
              ),
              isSelected: _showOperators,
              onPressed: () =>
                  setState(() => _showOperators = !_showOperators),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          validator: _validate,
        ),
        if (_showOperators) ...[
          const SizedBox(height: 8),
          _OperatorBar(onInsert: _insert),
        ],
        // Vista previa del total, solo cuando hay una operación.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final text = value.text.trim();
            final hasOperation = text.contains(_operatorPattern);
            if (!hasOperation) return const SizedBox(height: 4);
            final minor = Money.parseExpression(text);
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                minor == null
                    ? 'Expresión no válida'
                    : '= ${Money.format(minor)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: minor == null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Barra compacta con los operadores que el teclado numérico no ofrece.
class _OperatorBar extends StatelessWidget {
  const _OperatorBar({required this.onInsert});

  final void Function(String token) onInsert;

  @override
  Widget build(BuildContext context) {
    // (símbolo mostrado, texto insertado)
    const ops = [
      ('(', '('),
      (')', ')'),
      ('+', '+'),
      ('−', '-'),
      ('×', '*'),
      ('÷', '/'),
    ];
    // `canRequestFocus: false` evita que el botón robe el foco al campo, así
    // el teclado del sistema no se cierra al insertar un operador.
    return Row(
      children: [
        for (final (symbol, token) in ops)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Focus(
                canRequestFocus: false,
                child: OutlinedButton(
                  onPressed: () => onInsert(token),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(symbol, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
