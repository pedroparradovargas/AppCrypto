class Currency {
  final String id;
  final String name;
  final String symbol;
  final String image;
  final double currentPrice;
  final double marketCap;
  final int marketCapRank;
  final double priceChangePercentage24h;
  final double priceChangePercentage1h;
  final double priceChangePercentage7d;
  final double high24h;
  final double low24h;
  final double totalVolume;
  final List<double>? sparklineData;

  Currency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.currentPrice,
    required this.marketCap,
    required this.marketCapRank,
    required this.priceChangePercentage24h,
    required this.priceChangePercentage1h,
    required this.priceChangePercentage7d,
    required this.high24h,
    required this.low24h,
    required this.totalVolume,
    this.sparklineData,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    List<double>? sparkline;
    if (json['sparkline_in_7d'] != null &&
        json['sparkline_in_7d']['price'] != null) {
      sparkline = (json['sparkline_in_7d']['price'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return Currency(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      symbol: json['symbol'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0.0).toDouble(),
      marketCap: (json['market_cap'] ?? 0.0).toDouble(),
      marketCapRank: json['market_cap_rank'] ?? 0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] ?? 0.0).toDouble(),
      priceChangePercentage1h:
          (json['price_change_percentage_1h_in_currency'] ?? 0.0).toDouble(),
      priceChangePercentage7d:
          (json['price_change_percentage_7d_in_currency'] ?? 0.0).toDouble(),
      high24h: (json['high_24h'] ?? 0.0).toDouble(),
      low24h: (json['low_24h'] ?? 0.0).toDouble(),
      totalVolume: (json['total_volume'] ?? 0.0).toDouble(),
      sparklineData: sparkline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'image': image,
      'current_price': currentPrice,
      'market_cap': marketCap,
      'market_cap_rank': marketCapRank,
      'price_change_percentage_24h': priceChangePercentage24h,
      'price_change_percentage_1h_in_currency': priceChangePercentage1h,
      'price_change_percentage_7d_in_currency': priceChangePercentage7d,
      'high_24h': high24h,
      'low_24h': low24h,
      'total_volume': totalVolume,
    };
  }
}
