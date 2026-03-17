/// Modelo de datos OHLCV para graficas de velas (candlestick)
class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  /// Parsear respuesta OHLC de CoinGecko: [timestamp, open, high, low, close]
  factory CandleData.fromCoinGeckoOHLC(List<dynamic> data) {
    return CandleData(
      date: DateTime.fromMillisecondsSinceEpoch(data[0] as int),
      open: (data[1] as num).toDouble(),
      high: (data[2] as num).toDouble(),
      low: (data[3] as num).toDouble(),
      close: (data[4] as num).toDouble(),
    );
  }

  CandleData copyWith({double? volume}) {
    return CandleData(
      date: date,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}
