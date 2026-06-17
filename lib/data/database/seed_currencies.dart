/// Monedas sembradas en el primer arranque (y en la migración a multimoneda).
/// CUP es la predeterminada.
class SeedCurrency {
  const SeedCurrency(this.code, this.name, this.symbol, {this.isDefault = false});
  final String code;
  final String name;
  final String symbol;
  final bool isDefault;
}

const kDefaultCurrencies = [
  SeedCurrency('CUP', 'Peso cubano', r'$', isDefault: true),
  SeedCurrency('USD', 'Dólar estadounidense', r'US$'),
  SeedCurrency('EUR', 'Euro', '€'),
];
