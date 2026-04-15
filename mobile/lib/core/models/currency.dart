enum Currency {
  BYN(code: 'BYN', symbol: 'BYN', decimalDigits: 0),
  USD(code: 'USD', symbol: '\$', decimalDigits: 2),
  EUR(code: 'EUR', symbol: '€', decimalDigits: 2),
  RUB(code: 'RUB', symbol: '₽', decimalDigits: 2);

  final String code;
  final String symbol;
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.symbol,
    required this.decimalDigits,
  });

  factory Currency.fromCode(String? code) {
    if (code == null) return BYN;
    return values.firstWhere(
          (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => BYN,
    );
  }

  String get displayName => '$code ($symbol)';
}