import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Botón punteado de "añadir" del diseño, reutilizable en las listas.
class DashedButton extends StatelessWidget {
  const DashedButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.bd3, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20, color: t.gold),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: t.gold, fontSize: 13.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
