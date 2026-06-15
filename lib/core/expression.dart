/// Evaluador de expresiones aritméticas simples para los campos de importe.
///
/// Soporta `+`, `-`, `*`, `/`, paréntesis y precedencia estándar
/// (`*` y `/` antes que `+` y `-`). La coma se trata como separador decimal,
/// igual que el punto. Devuelve `null` ante cualquier entrada inválida
/// (texto suelto, paréntesis desbalanceados, división por cero, etc.).
///
/// Es un parser de descenso recursivo: pura lógica, sin estado global, fácil
/// de testear. NO usa `eval` ni nada que ejecute código arbitrario.
///
/// Gramática:
///   expr   := term (('+' | '-') term)*
///   term   := factor (('*' | '/') factor)*
///   factor := number | '(' expr ')' | ('+' | '-') factor
double? evaluateExpression(String input) {
  final normalized = input.replaceAll(',', '.').trim();
  if (normalized.isEmpty) return null;
  try {
    final parser = _Parser(normalized);
    final value = parser.parseExpression();
    parser.expectEnd();
    if (value.isNaN || value.isInfinite) return null;
    return value;
  } on _ParseError {
    return null;
  }
}

class _ParseError implements Exception {}

class _Parser {
  _Parser(this._src);

  final String _src;
  int _pos = 0;

  void _skipSpaces() {
    while (_pos < _src.length && _src[_pos] == ' ') {
      _pos++;
    }
  }

  bool get _atEnd {
    _skipSpaces();
    return _pos >= _src.length;
  }

  String get _current => _src[_pos];

  void expectEnd() {
    if (!_atEnd) throw _ParseError();
  }

  double parseExpression() {
    var value = _parseTerm();
    while (!_atEnd && (_current == '+' || _current == '-')) {
      final op = _current;
      _pos++;
      final rhs = _parseTerm();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (!_atEnd && (_current == '*' || _current == '/')) {
      final op = _current;
      _pos++;
      final rhs = _parseFactor();
      if (op == '*') {
        value = value * rhs;
      } else {
        if (rhs == 0) throw _ParseError(); // división por cero
        value = value / rhs;
      }
    }
    return value;
  }

  double _parseFactor() {
    if (_atEnd) throw _ParseError();
    final c = _current;
    if (c == '+') {
      _pos++;
      return _parseFactor();
    }
    if (c == '-') {
      _pos++;
      return -_parseFactor();
    }
    if (c == '(') {
      _pos++;
      final value = parseExpression();
      _skipSpaces();
      if (_atEnd || _current != ')') throw _ParseError();
      _pos++; // consume ')'
      return value;
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipSpaces();
    final start = _pos;
    var sawDot = false;
    while (_pos < _src.length) {
      final ch = _src[_pos];
      if (ch == '.') {
        if (sawDot) break; // segundo punto: fin del número
        sawDot = true;
        _pos++;
      } else if (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) {
        _pos++;
      } else {
        break;
      }
    }
    if (_pos == start) throw _ParseError();
    final text = _src.substring(start, _pos);
    final value = double.tryParse(text);
    if (value == null) throw _ParseError();
    return value;
  }
}
