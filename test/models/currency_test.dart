import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/currency.dart';

void main() {
  group('Currency Model', () {
    test('fromJson creates a valid Currency', () {
      final json = {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'btc',
        'image': 'https://example.com/btc.png',
        'current_price': 50000.0,
        'market_cap': 1000000000.0,
        'market_cap_rank': 1,
        'price_change_percentage_24h': 2.5,
        'price_change_percentage_1h_in_currency': 0.1,
        'price_change_percentage_7d_in_currency': 5.0,
        'high_24h': 51000.0,
        'low_24h': 49000.0,
        'total_volume': 500000000.0,
      };

      final currency = Currency.fromJson(json);

      expect(currency.id, 'bitcoin');
      expect(currency.name, 'Bitcoin');
      expect(currency.symbol, 'btc');
      expect(currency.currentPrice, 50000.0);
      expect(currency.marketCapRank, 1);
      expect(currency.priceChangePercentage24h, 2.5);
      expect(currency.high24h, 51000.0);
      expect(currency.low24h, 49000.0);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'name': null,
        'symbol': null,
        'image': null,
        'current_price': null,
        'market_cap': null,
        'market_cap_rank': null,
        'price_change_percentage_24h': null,
        'price_change_percentage_1h_in_currency': null,
        'price_change_percentage_7d_in_currency': null,
        'high_24h': null,
        'low_24h': null,
        'total_volume': null,
      };

      final currency = Currency.fromJson(json);

      expect(currency.id, '');
      expect(currency.name, 'Unknown');
      expect(currency.currentPrice, 0.0);
      expect(currency.marketCapRank, 0);
    });

    test('fromJson parses sparkline data', () {
      final json = {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'btc',
        'image': 'https://example.com/btc.png',
        'current_price': 50000.0,
        'market_cap': 1000000000.0,
        'market_cap_rank': 1,
        'price_change_percentage_24h': 2.5,
        'price_change_percentage_1h_in_currency': 0.1,
        'price_change_percentage_7d_in_currency': 5.0,
        'high_24h': 51000.0,
        'low_24h': 49000.0,
        'total_volume': 500000000.0,
        'sparkline_in_7d': {
          'price': [49000.0, 49500.0, 50000.0, 50500.0],
        },
      };

      final currency = Currency.fromJson(json);

      expect(currency.sparklineData, isNotNull);
      expect(currency.sparklineData!.length, 4);
      expect(currency.sparklineData![0], 49000.0);
    });

    test('toJson produces valid map', () {
      final currency = Currency(
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'eth',
        image: 'https://example.com/eth.png',
        currentPrice: 3000.0,
        marketCap: 500000000.0,
        marketCapRank: 2,
        priceChangePercentage24h: -1.5,
        priceChangePercentage1h: 0.2,
        priceChangePercentage7d: 3.0,
        high24h: 3100.0,
        low24h: 2900.0,
        totalVolume: 200000000.0,
      );

      final json = currency.toJson();

      expect(json['id'], 'ethereum');
      expect(json['name'], 'Ethereum');
      expect(json['current_price'], 3000.0);
      expect(json['market_cap_rank'], 2);
    });

    test('toJson and fromJson are symmetric', () {
      final original = Currency(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'btc',
        image: 'https://example.com/btc.png',
        currentPrice: 50000.0,
        marketCap: 1000000000.0,
        marketCapRank: 1,
        priceChangePercentage24h: 2.5,
        priceChangePercentage1h: 0.1,
        priceChangePercentage7d: 5.0,
        high24h: 51000.0,
        low24h: 49000.0,
        totalVolume: 500000000.0,
      );

      final json = original.toJson();
      final restored = Currency.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.currentPrice, original.currentPrice);
      expect(restored.marketCapRank, original.marketCapRank);
    });
  });
}
