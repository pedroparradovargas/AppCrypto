class Currency {
  final String name;
  final String symbol;
  final double currentPrice;
  final double priceChangePercentage1h;

  Currency({
    required this.name,
    required this.symbol,
    required this.currentPrice,
    required this.priceChangePercentage1h,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      name: json['name'] ?? 'Unknown',
      symbol: json['symbol'] ?? '',
      currentPrice: (json['current_price'] ?? 0.0).toDouble(),
      priceChangePercentage1h:
          (json['price_change_percentage_1h_in_currency'] ?? 0.0).toDouble(),
    );
  }
}
