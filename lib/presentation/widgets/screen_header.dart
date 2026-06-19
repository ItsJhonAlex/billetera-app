import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Encabezado de pantalla del diseño: título serif (Spectral) + subtítulo
/// opcional, y flecha de volver opcional.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.fromLTRB(onBack != null ? 8 : 20, 10, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: t.tx1),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: BilleteraTheme.displayFont,
                        fontSize: 24,
                        color: t.tx1)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: TextStyle(color: t.txm, fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
