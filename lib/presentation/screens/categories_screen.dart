import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/material_icon.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../providers/providers.dart';
import 'category_form_screen.dart';

/// Gestión de categorías: lista por tipo con acciones de crear/editar/archivar.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final gastos =
        categories.where((c) => c.kind == CategoryKind.gasto).toList();
    final ingresos =
        categories.where((c) => c.kind == CategoryKind.ingreso).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        children: [
          _SectionHeader('Gastos'),
          for (final c in gastos) _CategoryTile(category: c),
          const SizedBox(height: 8),
          _SectionHeader('Ingresos'),
          for (final c in ingresos) _CategoryTile(category: c),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {CategoryRow? category}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});
  final CategoryRow category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(category.colorValue).withValues(alpha: 0.2),
        child: Icon(
          materialIcon(category.iconCodePoint),
          color: Color(category.colorValue),
        ),
      ),
      title: Text(category.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmArchive(context, ref),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryFormScreen(category: category),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Borrar "${category.name}"?'),
        content: const Text(
            'Los movimientos que ya la usan conservan su importe; solo dejará '
            'de aparecer al crear nuevos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(walletRepositoryProvider).archiveCategory(category.id);
    }
  }
}
