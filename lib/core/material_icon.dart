import 'package:flutter/material.dart';

/// Construye un [IconData] de Material a partir de un codepoint guardado en la
/// base de datos.
///
/// Como los codepoints son dinámicos (los elige el usuario al crear categorías),
/// el tree-shaking de iconos no puede analizarlos: la app se compila con
/// `--no-tree-shake-icons`. El `ignore` centraliza ese aviso en un solo lugar.
IconData materialIcon(int codePoint) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}
