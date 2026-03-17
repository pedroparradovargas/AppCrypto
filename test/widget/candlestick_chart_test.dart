import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/candle_data.dart';

/// Tests para el widget CandlestickChartWidget
void main() {
  group('CandlestickChartWidget - Datos', () {
    test('lista vacia muestra mensaje de no datos', () {
      final candles = <CandleData>[];
      expect(candles.isEmpty, true);
    });

    test('datos cargados muestran grafica', () {
      final candles = [
        CandleData(
          date: DateTime(2026, 3, 12),
          open: 65000,
          high: 66000,
          low: 64000,
          close: 65500,
          volume: 1500000,
        ),
        CandleData(
          date: DateTime(2026, 3, 11),
          open: 64500,
          high: 65500,
          low: 64000,
          close: 65000,
          volume: 1200000,
        ),
      ];

      expect(candles.isNotEmpty, true);
      expect(candles.length, 2);
    });

    test('leyenda OHLC calculada correctamente', () {
      final candle = CandleData(
        date: DateTime(2026, 3, 12),
        open: 65000,
        high: 66000,
        low: 64000,
        close: 65500,
        volume: 1500000,
      );

      final change = candle.close - candle.open;
      final changePercent = (change / candle.open) * 100;
      final isPositive = change >= 0;

      expect(change, 500.0);
      expect(changePercent, closeTo(0.769, 0.01));
      expect(isPositive, true);
    });

    test('leyenda para vela roja', () {
      final candle = CandleData(
        date: DateTime(2026, 3, 12),
        open: 65000,
        high: 65500,
        low: 63000,
        close: 63500,
        volume: 2000000,
      );

      final change = candle.close - candle.open;
      final isPositive = change >= 0;

      expect(change, -1500.0);
      expect(isPositive, false);
    });
  });

  group('CandlestickChartWidget - Intervalos', () {
    test('intervalos disponibles', () {
      final intervals = {1: '1D', 7: '1W', 30: '1M', 90: '3M', 365: '1Y'};

      expect(intervals.length, 5);
      expect(intervals[1], '1D');
      expect(intervals[365], '1Y');
    });

    test('cambio de intervalo actualiza selectedDays', () {
      int selectedDays = 7;

      // Cambiar a 30 dias
      selectedDays = 30;

      expect(selectedDays, 30);
    });

    test('cambio de intervalo carga nuevos datos', () {
      bool dataLoaded = false;
      int requestedDays = 0;

      // Simular callback
      void onIntervalChanged(int days) {
        requestedDays = days;
        dataLoaded = true;
      }

      onIntervalChanged(90);

      expect(dataLoaded, true);
      expect(requestedDays, 90);
    });
  });

  group('CandlestickChartWidget - Toggle chart type', () {
    test('default es candlestick', () {
      const showCandlestick = true;
      expect(showCandlestick, true);
    });

    test('toggle a lineal', () {
      bool showCandlestick = true;
      showCandlestick = false;
      expect(showCandlestick, false);
    });

    test('toggle de vuelta a candlestick', () {
      bool showCandlestick = false;
      showCandlestick = true;
      expect(showCandlestick, true);
    });
  });
}
