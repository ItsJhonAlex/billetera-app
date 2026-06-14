import 'package:flutter/material.dart';

import 'categories_screen.dart';

/// Ajustes de la app. Por ahora: gestión de categorías y datos de la app.
/// Más adelante: presupuestos, backup/exportar, moneda.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categorías'),
            subtitle: const Text('Crear, editar o borrar categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.payments),
            title: Text('Moneda'),
            subtitle: Text('CUP — Peso cubano'),
            trailing: Text('Próximamente'),
          ),
          const ListTile(
            leading: Icon(Icons.savings),
            title: Text('Presupuestos por categoría'),
            subtitle: Text('Llegará en una próxima versión'),
            trailing: Icon(Icons.lock_clock),
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Billetera',
            applicationVersion: '1.0.0',
            aboutBoxChildren: [
              Text('Tu presupuesto personal, sin conexión.'),
            ],
          ),
        ],
      ),
    );
  }
}
