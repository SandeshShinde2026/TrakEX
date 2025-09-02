class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double exchangeRate; // Rate relative to USD (1 USD = exchangeRate of this currency)

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.exchangeRate = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'exchangeRate': exchangeRate,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      flag: map['flag'] ?? '',
      exchangeRate: (map['exchangeRate'] ?? 1.0).toDouble(),
    );
  }

  CurrencyModel copyWith({
    String? code,
    String? name,
    String? symbol,
    String? flag,
    double? exchangeRate,
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      flag: flag ?? this.flag,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$flag $symbol $name ($code)';

  // Format amount with this currency
  String formatAmount(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Convert amount from this currency to USD
  double toUSD(double amount) {
    return amount / exchangeRate;
  }

  // Convert amount from USD to this currency
  double fromUSD(double usdAmount) {
    return usdAmount * exchangeRate;
  }

  // Convert amount from this currency to another currency
  double convertTo(double amount, CurrencyModel targetCurrency) {
    final usdAmount = toUSD(amount);
    return targetCurrency.fromUSD(usdAmount);
  }
}
