import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../providers/providers.dart';

/// Iconos disponibles para categorías. Constantes para que el tree-shaking de
/// iconos funcione.
const List<IconData> kPickableIcons = [
  Icons.restaurant,
  Icons.directions_bus,
  Icons.home,
  Icons.shopping_bag,
  Icons.local_hospital,
  Icons.bolt,
  Icons.movie,
  Icons.school,
  Icons.payments,
  Icons.card_giftcard,
  Icons.sell,
  Icons.sports_esports,
  Icons.pets,
  Icons.flight,
  Icons.fitness_center,
  Icons.more_horiz,
];

const List<Color> kPickableColors = [
  Color(0xFFEF5350),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFFAB47BC),
  Color(0xFF26A69A),
  Color(0xFF8D6E63),
  Color(0xFFEC407A),
  Color(0xFF7E57C2),
  Color(0xFF78909C),
];

/// Crea o edita una categoría.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category});

  final CategoryRow? category;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late CategoryKind _kind;
  late int _iconCodePoint;
  late int _colorValue;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _kind = c?.kind ?? CategoryKind.gasto;
    _iconCodePoint = c?.iconCodePoint ?? kPickableIcons.first.codePoint;
    _colorValue = c?.colorValue ?? kPickableColors.first.toARGB32();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(walletRepositoryProvider);
    if (_isEdit) {
      await repo.updateCategory(widget.category!.copyWith(
        name: _name.text.trim(),
        kind: _kind,
        iconCodePoint: _iconCodePoint,
        colorValue: _colorValue,
      ));
    } else {
      await repo.createCategory(
        name: _name.text.trim(),
        kind: _kind,
        iconCodePoint: _iconCodePoint,
        colorValue: _colorValue,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEdit ? 'Editar categoría' : 'Nueva categoría')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(value: CategoryKind.gasto, label: Text('Gasto')),
                ButtonSegment(
                    value: CategoryKind.ingreso, label: Text('Ingreso')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 24),
            Text('Icono', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in kPickableIcons)
                  _PickChip(
                    selected: icon.codePoint == _iconCodePoint,
                    color: Color(_colorValue),
                    onTap: () =>
                        setState(() => _iconCodePoint = icon.codePoint),
                    child: Icon(icon),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in kPickableColors)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _colorValue = color.toARGB32()),
                    child: CircleAvatar(
                      backgroundColor: color,
                      child: color.toARGB32() == _colorValue
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Guardar' : 'Crear categoría'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: IconTheme(
          data: IconThemeData(color: selected ? color : Colors.white70),
          child: Center(child: child),
        ),
      ),
    );
  }
}
