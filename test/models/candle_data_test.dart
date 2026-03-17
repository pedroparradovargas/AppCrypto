import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/candle_data.dart';

void main() {
  group('CandleData', () {
    test('fromCoinGeckoOHLC parsea datos correctamente', () {
      final raw = [1710000000000, 65000.0, 66000.0, 64000.0, 65500.0];

      final candle = CandleData.fromCoinGeckoOHLC(raw);

      expect(candle.date, DateTime.fromMillisecondsSinceEpoch(1710000000000));
      expect(candle.open, 65000.0);
      expect(candle.high, 66000.0);
      expect(candle.low, 64000.0);
      expect(candle.close, 65500.0);
      expect(candle.volume, 0); // default sin volumen
    });

    test('fromCoinGeckoOHLC maneja numeros enteros', () {
      final raw = [1710000000000, 65000, 66000, 64000, 65500];

      final candle = CandleData.fromCoinGeckoOHLC(raw);

      expect(candle.open, 65000.0);
      expect(candle.high, 66000.0);
      expect(candle.low, 64000.0);
      expect(candle.close, 65500.0);
    });

    test('copyWith actualiza volumen', () {
      final candle = CandleData(
        date: DateTime(2026, 3, 12),
        open: 100,
        high: 110,
        low: 95,
        close: 105,
      );

      final withVolume = candle.copyWith(volume: 1500000);

      expect(withVolume.volume, 1500000);
      expect(withVolume.open, candle.open);
      expect(withVolume.close, candle.close);
    });

    test('toJson produce JSON correcto', () {
      final candle = CandleData(
        date: DateTime(2026, 3, 12),
        open: 100,
        high: 110,
        low: 95,
        close: 105,
        volume: 5000,
      );

      final json = candle.toJson();

      expect(json['open'], 100);
      expect(json['high'], 110);
      expect(json['low'], 95);
      expect(json['close'], 105);
      expect(json['volume'], 5000);
      expect(json['date'], isA<int>());
    });

    test('vela verde: close > open', () {
      final candle = CandleData(
        date: DateTime.now(),
        open: 100,
        high: 110,
        low: 95,
        close: 108,
      );

      expect(candle.close > candle.open, true);
    });

    test('vela roja: close < open', () {
      final candle = CandleData(
        date: DateTime.now(),
        open: 100,
        high: 105,
        low: 90,
        close: 92,
      );

      expect(candle.close < candle.open, true);
    });
  });
}
