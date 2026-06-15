import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'presentation/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los datos de formato de fecha/número para español; sin esto,
  // DateFormat(..., 'es') y NumberFormat con locale lanzan LocaleDataException.
  await initializeDateFormatting('es');
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
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
