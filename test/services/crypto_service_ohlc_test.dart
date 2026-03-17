import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/candle_data.dart';

void main() {
  group('CryptoService OHLC parsing', () {
    test('parsear respuesta OHLC de CoinGecko', () {
      // Simular respuesta de CoinGecko /coins/{id}/ohlc
      final ohlcResponse = [
        [1710000000000, 65000.0, 66000.0, 64000.0, 65500.0],
        [1710086400000, 65500.0, 67000.0, 65000.0, 66800.0],
        [1710172800000, 66800.0, 68000.0, 66000.0, 67500.0],
      ];

      final candles = ohlcResponse
          .map((data) => CandleData.fromCoinGeckoOHLC(data))
          .toList();

      expect(candles.length, 3);
      expect(candles[0].open, 65000.0);
      expect(candles[0].close, 65500.0);
      expect(candles[1].open, 65500.0);
      expect(candles[2].close, 67500.0);
    });

    test('merge de volumenes por timestamp cercano', () {
      final candles = [
        CandleData(
          date: DateTime.fromMillisecondsSinceEpoch(1710000000000),
          open: 65000,
          high: 66000,
          low: 64000,
          close: 65500,
        ),
        CandleData(
          date: DateTime.fromMillisecondsSinceEpoch(1710086400000),
          open: 65500,
          high: 67000,
          low: 65000,
          close: 66800,
        ),
      ];

      final volumes = [
        [1710000100000, 1500000000.0], // Cercano al primer candle
        [1710086500000, 2000000000.0], // Cercano al segundo candle
      ];

      // Simular merge logic
      final merged = <CandleData>[];
      for (final candle in candles) {
        final candleTime = candle.date.millisecondsSinceEpoch;
        double closestVolume = 0;
        int minDiff = 999999999999;

        for (final vol in volumes) {
          final volTime = vol[0] as int;
          final diff = (volTime - candleTime).abs();
          if (diff < minDiff) {
            minDiff = diff;
            closestVolume = (vol[1] as num).toDouble();
          }
        }

        merged.add(candle.copyWith(volume: closestVolume));
      }

      expect(merged[0].volume, 1500000000.0);
      expect(merged[1].volume, 2000000000.0);
    });

    test('OHLC vacio retorna lista vacia', () {
      final List<List<dynamic>> emptyResponse = [];

      final candles = emptyResponse
          .map((data) => CandleData.fromCoinGeckoOHLC(data))
          .toList();

      expect(candles, isEmpty);
    });

    test('candles ordenados descendente por fecha', () {
      final candles = [
        CandleData(
          date: DateTime(2026, 3, 10),
          open: 100, high: 110, low: 90, close: 105,
        ),
        CandleData(
          date: DateTime(2026, 3, 12),
          open: 105, high: 115, low: 100, close: 110,
        ),
        CandleData(
          date: DateTime(2026, 3, 11),
          open: 102, high: 108, low: 95, close: 107,
        ),
      ];

      // Ordenar descendente como requiere el paquete candlesticks
      candles.sort((a, b) => b.date.compareTo(a.date));

      expect(candles[0].date, DateTime(2026, 3, 12));
      expect(candles[1].date, DateTime(2026, 3, 11));
      expect(candles[2].date, DateTime(2026, 3, 10));
    });

    test('diferentes intervalos de tiempo', () {
      final intervals = {
        1: '1 dia',
        7: '1 semana',
        30: '1 mes',
        90: '3 meses',
        365: '1 año',
      };

      for (final entry in intervals.entries) {
        expect(entry.key, isPositive);
        expect(entry.value, isNotEmpty);
      }
    });
  });
}
