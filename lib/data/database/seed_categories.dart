import 'package:flutter/material.dart';

import '../../domain/enums.dart';

/// Una categoría que se siembra en el primer arranque.
class SeedCategory {
  const SeedCategory(this.name, this.kind, this.icon, this.color);

  final String name;
  final CategoryKind kind;
  final IconData icon;
  final Color color;
}

/// Categorías por defecto. El usuario puede editarlas, crearlas o borrarlas.
///
/// Se importa Material solo para usar codepoints de iconos y colores reales
/// (evita adivinar codepoints a mano).
const List<SeedCategory> kDefaultCategories = [
  // Gastos
  SeedCategory('Comida', CategoryKind.gasto, Icons.restaurant, Color(0xFFEF5350)),
  SeedCategory('Transporte', CategoryKind.gasto, Icons.directions_bus, Color(0xFF42A5F5)),
  SeedCategory('Hogar', CategoryKind.gasto, Icons.home, Color(0xFF8D6E63)),
  SeedCategory('Compras', CategoryKind.gasto, Icons.shopping_bag, Color(0xFFAB47BC)),
  SeedCategory('Salud', CategoryKind.gasto, Icons.local_hospital, Color(0xFF26A69A)),
  SeedCategory('Servicios', CategoryKind.gasto, Icons.bolt, Color(0xFFFFCA28)),
  SeedCategory('Ocio', CategoryKind.gasto, Icons.movie, Color(0xFF7E57C2)),
  SeedCategory('Educación', CategoryKind.gasto, Icons.school, Color(0xFF5C6BC0)),
  SeedCategory('Otros gastos', CategoryKind.gasto, Icons.more_horiz, Color(0xFF78909C)),
  // Ingresos
  SeedCategory('Salario', CategoryKind.ingreso, Icons.payments, Color(0xFF66BB6A)),
  SeedCategory('Regalos', CategoryKind.ingreso, Icons.card_giftcard, Color(0xFFEC407A)),
  SeedCategory('Ventas', CategoryKind.ingreso, Icons.sell, Color(0xFF26C6DA)),
  SeedCategory('Otros ingresos', CategoryKind.ingreso, Icons.more_horiz, Color(0xFF9CCC65)),
];
