import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'categories_screen.dart';

/// Ajustes de la app: gestión de categorías, datos de la app e información
/// "Acerca de" (autor y código fuente). Más adelante: presupuestos, backup,
/// moneda configurable.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _author = 'ItsJhonAlex';
  static const _repoUrl = 'https://github.com/ItsJhonAlex/billetera-app';

  Future<void> _openRepo(BuildContext context) async {
    final uri = Uri.parse(_repoUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Billetera',
      applicationVersion: 'Versión $_appVersion',
      applicationIcon: const _AppLogo(size: 56),
      children: [
        const SizedBox(height: 8),
        const Text('Tu presupuesto personal, sin conexión.'),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 20),
            const SizedBox(width: 8),
            Text('Autor: $_author'),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _openRepo(context),
          child: const Row(
            children: [
              Icon(Icons.code, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _repoUrl,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categorías'),
            subtitle: const Text('Crear, editar o borrar categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.payments),
            title: Text('Moneda'),
            subtitle: Text('CUP — Peso cubano'),
            trailing: Text('Próximamente'),
          ),
          const _SectionHeader('Próximamente'),
          const ListTile(
            leading: Icon(Icons.savings),
            title: Text('Presupuestos por categoría'),
            subtitle: Text('Fija un límite mensual por categoría'),
            trailing: Icon(Icons.lock_clock),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.backup_outlined),
            title: Text('Copia de seguridad'),
            subtitle: Text('Exportar e importar tus datos'),
            trailing: Icon(Icons.lock_clock),
            enabled: false,
          ),
          const _SectionHeader('Acerca de'),
          ListTile(
            leading: const _AppLogo(size: 40),
            title: const Text('Billetera'),
            subtitle: const Text('Versión $_appVersion'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Autor'),
            subtitle: const Text(_author),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Código fuente'),
            subtitle: const Text('github.com/ItsJhonAlex/billetera-app'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openRepo(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Título de sección con el color de acento.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// El logo de la app, redondeado.
class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icon/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
