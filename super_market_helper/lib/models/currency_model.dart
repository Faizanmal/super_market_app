/// Currency model for multi-currency support
class CurrencyModel {
  final int id;
  final String code;
  final String name;
  final String symbol;
  final double exchangeRate;
  final bool isBaseCurrency;
  final bool isActive;
  final DateTime lastUpdated;

  CurrencyModel({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    required this.exchangeRate,
    required this.isBaseCurrency,
    required this.isActive,
    required this.lastUpdated,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      exchangeRate: double.parse(json['exchange_rate'].toString()),
      isBaseCurrency: json['is_base_currency'],
      isActive: json['is_active'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'exchange_rate': exchangeRate,
      'is_base_currency': isBaseCurrency,
      'is_active': isActive,
    };
  }

  String formatAmount(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class CurrencyConversion {
  final double originalAmount;
  final String fromCurrency;
  final String toCurrency;
  final double convertedAmount;
  final double exchangeRate;

  CurrencyConversion({
    required this.originalAmount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    required this.exchangeRate,
  });

  factory CurrencyConversion.fromJson(Map<String, dynamic> json) {
    return CurrencyConversion(
      originalAmount: double.parse(json['original_amount'].toString()),
      fromCurrency: json['from_currency'],
      toCurrency: json['to_currency'],
      convertedAmount: double.parse(json['converted_amount'].toString()),
      exchangeRate: double.parse(json['exchange_rate'].toString()),
    );
  }
}
