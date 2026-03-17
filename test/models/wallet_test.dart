import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/wallet.dart';

void main() {
  group('WalletItem', () {
    test('totalValue is calculated correctly', () {
      final item = WalletItem(
        currencyId: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        image: '',
        amount: 2.0,
        averageBuyPrice: 50000.0,
      );

      expect(item.totalValue, 100000.0);
    });

    test('fromJson creates a valid WalletItem', () {
      final json = {
        'currencyId': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'image': 'https://example.com/btc.png',
        'amount': 1.5,
        'averageBuyPrice': 45000.0,
      };

      final item = WalletItem.fromJson(json);

      expect(item.currencyId, 'bitcoin');
      expect(item.amount, 1.5);
      expect(item.averageBuyPrice, 45000.0);
      expect(item.totalValue, 67500.0);
    });

    test('toJson produces valid map', () {
      final item = WalletItem(
        currencyId: 'ethereum',
        name: 'Ethereum',
        symbol: 'ETH',
        image: '',
        amount: 10.0,
        averageBuyPrice: 3000.0,
      );

      final json = item.toJson();

      expect(json['currencyId'], 'ethereum');
      expect(json['amount'], 10.0);
      expect(json['averageBuyPrice'], 3000.0);
    });

    test('copyWith updates specified fields', () {
      final item = WalletItem(
        currencyId: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        image: '',
        amount: 1.0,
        averageBuyPrice: 50000.0,
      );

      final updated = item.copyWith(amount: 2.0, averageBuyPrice: 48000.0);

      expect(updated.amount, 2.0);
      expect(updated.averageBuyPrice, 48000.0);
      expect(updated.currencyId, 'bitcoin'); // unchanged
    });

    test('toJson and fromJson are symmetric', () {
      final original = WalletItem(
        currencyId: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        image: 'img.png',
        amount: 3.5,
        averageBuyPrice: 42000.0,
      );

      final json = original.toJson();
      final restored = WalletItem.fromJson(json);

      expect(restored.currencyId, original.currencyId);
      expect(restored.amount, original.amount);
      expect(restored.averageBuyPrice, original.averageBuyPrice);
    });
  });

  group('Wallet', () {
    test('default wallet has 10000 USD and no items', () {
      final wallet = Wallet();

      expect(wallet.usdBalance, 10000.0);
      expect(wallet.items, isEmpty);
    });

    test('totalValueInUsd includes both USD and crypto', () {
      final wallet = Wallet(
        usdBalance: 5000.0,
        items: [
          WalletItem(
            currencyId: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'BTC',
            image: '',
            amount: 1.0,
            averageBuyPrice: 50000.0,
          ),
          WalletItem(
            currencyId: 'ethereum',
            name: 'Ethereum',
            symbol: 'ETH',
            image: '',
            amount: 5.0,
            averageBuyPrice: 3000.0,
          ),
        ],
      );

      // 5000 + (1 * 50000) + (5 * 3000) = 5000 + 50000 + 15000 = 70000
      expect(wallet.totalValueInUsd, 70000.0);
    });

    test('fromJson creates a valid Wallet', () {
      final json = {
        'usdBalance': 7500.0,
        'items': [
          {
            'currencyId': 'bitcoin',
            'name': 'Bitcoin',
            'symbol': 'BTC',
            'image': '',
            'amount': 0.5,
            'averageBuyPrice': 48000.0,
          },
        ],
      };

      final wallet = Wallet.fromJson(json);

      expect(wallet.usdBalance, 7500.0);
      expect(wallet.items.length, 1);
      expect(wallet.items[0].currencyId, 'bitcoin');
    });

    test('fromJson handles null items list', () {
      final json = {
        'usdBalance': 10000.0,
        'items': null,
      };

      final wallet = Wallet.fromJson(json);

      expect(wallet.items, isEmpty);
      expect(wallet.usdBalance, 10000.0);
    });

    test('copyWith updates specified fields', () {
      final wallet = Wallet(usdBalance: 10000.0);
      final updated = wallet.copyWith(usdBalance: 8000.0);

      expect(updated.usdBalance, 8000.0);
      expect(updated.items, isEmpty);
    });

    test('toJson and fromJson are symmetric', () {
      final original = Wallet(
        usdBalance: 5500.0,
        items: [
          WalletItem(
            currencyId: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'BTC',
            image: '',
            amount: 2.0,
            averageBuyPrice: 45000.0,
          ),
        ],
      );

      final json = original.toJson();
      final restored = Wallet.fromJson(json);

      expect(restored.usdBalance, original.usdBalance);
      expect(restored.items.length, original.items.length);
      expect(restored.items[0].amount, original.items[0].amount);
    });
  });
}
