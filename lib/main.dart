import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'presentation/screens/home_shell.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Mantiene el splash nativo mientras se inicializa la app.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  // Carga los datos de formato de fecha/número para español; sin esto,
  // DateFormat(..., 'es') y NumberFormat con locale lanzan LocaleDataException.
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: BilleteraApp()));
  // Quita el splash al pintar el primer frame (evita el parpadeo en blanco).
  binding.addPostFrameCallback((_) => FlutterNativeSplash.remove());
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
