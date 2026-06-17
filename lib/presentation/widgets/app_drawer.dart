import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../screens/categories_screen.dart';
import '../screens/currencies_screen.dart';
import '../screens/settings_screen.dart';

/// Menú lateral con accesos rápidos a las secciones secundarias.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _DrawerHeader(),
          _item(
            context,
            icon: Icons.category,
            label: 'Categorías',
            builder: (_) => const CategoriesScreen(),
          ),
          _item(
            context,
            icon: Icons.payments,
            label: 'Monedas',
            builder: (_) => const CurrenciesScreen(),
          ),
          const Divider(),
          _item(
            context,
            icon: Icons.settings,
            label: 'Ajustes',
            builder: (_) => const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required WidgetBuilder builder,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop(); // cierra el drawer
        Navigator.of(context).push(MaterialPageRoute(builder: builder));
      },
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BilleteraTheme.leatherLight, BilleteraTheme.leather],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/icon/logo.png', width: 56, height: 56),
          ),
          const SizedBox(height: 12),
          Text('Billetera',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Tu presupuesto, sin conexión',
              style: TextStyle(color: Color(0xFFB9AE9F), fontSize: 12)),
        ],
      ),
    );
  }
}
