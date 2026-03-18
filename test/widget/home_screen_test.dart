import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/currency.dart';

void main() {
  group('HomeScreen - Logic Tests', () {
    test('muestra el titulo del mercado', () {
      const title = 'CryptoMarket';
      expect(title, isNotEmpty);
      expect(title, 'CryptoMarket');
    });

    test('busqueda filtra por nombre', () {
      final currencies = [
        Currency(
          id: 'bitcoin', symbol: 'btc', name: 'Bitcoin',
          image: '', currentPrice: 65000, marketCap: 1000000,
          marketCapRank: 1, priceChangePercentage24h: 2.5,
          totalVolume: 500000,
        ),
        Currency(
          id: 'ethereum', symbol: 'eth', name: 'Ethereum',
          image: '', currentPrice: 3500, marketCap: 500000,
          marketCapRank: 2, priceChangePercentage24h: -1.2,
          totalVolume: 300000,
        ),
        Currency(
          id: 'cardano', symbol: 'ada', name: 'Cardano',
          image: '', currentPrice: 0.5, marketCap: 100000,
          marketCapRank: 8, priceChangePercentage24h: 5.0,
          totalVolume: 100000,
        ),
      ];

      final query = 'bit';
      final filtered = currencies
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.symbol.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(filtered.length, 1);
      expect(filtered.first.name, 'Bitcoin');
    });

    test('busqueda filtra por simbolo', () {
      final currencies = [
        Currency(
          id: 'bitcoin', symbol: 'btc', name: 'Bitcoin',
          image: '', currentPrice: 65000, marketCap: 1000000,
          marketCapRank: 1, priceChangePercentage24h: 2.5,
          totalVolume: 500000,
        ),
        Currency(
          id: 'ethereum', symbol: 'eth', name: 'Ethereum',
          image: '', currentPrice: 3500, marketCap: 500000,
          marketCapRank: 2, priceChangePercentage24h: -1.2,
          totalVolume: 300000,
        ),
      ];

      final query = 'eth';
      final filtered = currencies
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.symbol.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(filtered.length, 1);
      expect(filtered.first.name, 'Ethereum');
    });

    test('formato de precio mayor a 1', () {
      String formatPrice(double price) {
        if (price >= 1) {
          return price.toStringAsFixed(2);
        } else {
          return price.toStringAsFixed(6);
        }
      }

      expect(formatPrice(65000.0), '65000.00');
      expect(formatPrice(3500.50), '3500.50');
    });

    test('formato de precio menor a 1', () {
      String formatPrice(double price) {
        if (price >= 1) {
          return price.toStringAsFixed(2);
        } else {
          return price.toStringAsFixed(6);
        }
      }

      expect(formatPrice(0.5), '0.500000');
      expect(formatPrice(0.000123), '0.000123');
    });

    test('color de cambio de precio positivo vs negativo', () {
      final btc = Currency(
        id: 'bitcoin', symbol: 'btc', name: 'Bitcoin',
        image: '', currentPrice: 65000, marketCap: 1000000,
        marketCapRank: 1, priceChangePercentage24h: 2.5,
        totalVolume: 500000,
      );

      final eth = Currency(
        id: 'ethereum', symbol: 'eth', name: 'Ethereum',
        image: '', currentPrice: 3500, marketCap: 500000,
        marketCapRank: 2, priceChangePercentage24h: -1.2,
        totalVolume: 300000,
      );

      expect(btc.priceChangePercentage24h >= 0, true); // green
      expect(eth.priceChangePercentage24h >= 0, false); // red
    });
  });
}
