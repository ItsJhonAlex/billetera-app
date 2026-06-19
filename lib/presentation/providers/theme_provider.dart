import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instancia de SharedPreferences. Se inyecta en `main` con override.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override en main()'),
);

const _themeKey = 'themeMode';

/// Modo de tema (claro/oscuro), persistido. La app es oscura por defecto.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getString(_themeKey) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    ref.read(sharedPrefsProvider).setString(
          _themeKey,
          next == ThemeMode.light ? 'light' : 'dark',
        );
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
