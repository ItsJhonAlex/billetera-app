import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'presentation/screens/home_shell.dart';

void main() {
  runApp(const ProviderScope(child: BilleteraApp()));
}

class BilleteraApp extends StatelessWidget {
  const BilleteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billetera',
      debugShowCheckedModeBanner: false,
      theme: BilleteraTheme.dark(),
      home: const HomeShell(),
    );
  }
}
