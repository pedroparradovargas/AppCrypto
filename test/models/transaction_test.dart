import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    test('fromJson creates a valid Transaction', () {
      final json = {
        'id': '123',
        'currencyId': 'bitcoin',
        'currencyName': 'Bitcoin',
        'currencySymbol': 'BTC',
        'currencyImage': 'https://example.com/btc.png',
        'type': 'buy',
        'amount': 0.5,
        'pricePerUnit': 50000.0,
        'totalValue': 25000.0,
        'timestamp': '2026-03-01T10:00:00.000',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, '123');
      expect(transaction.currencyId, 'bitcoin');
      expect(transaction.type, TransactionType.buy);
      expect(transaction.amount, 0.5);
      expect(transaction.pricePerUnit, 50000.0);
      expect(transaction.totalValue, 25000.0);
    });

    test('fromJson defaults to buy for unknown type', () {
      final json = {
        'id': '123',
        'currencyId': 'bitcoin',
        'currencyName': 'Bitcoin',
        'currencySymbol': 'BTC',
        'currencyImage': '',
        'type': 'unknown_type',
        'amount': 1.0,
        'pricePerUnit': 50000.0,
        'totalValue': 50000.0,
        'timestamp': '2026-03-01T10:00:00.000',
      };

      final transaction = Transaction.fromJson(json);
      expect(transaction.type, TransactionType.buy);
    });

    test('toJson produces valid map', () {
      final transaction = Transaction(
        id: '456',
        currencyId: 'ethereum',
        currencyName: 'Ethereum',
        currencySymbol: 'ETH',
        currencyImage: '',
        type: TransactionType.sell,
        amount: 5.0,
        pricePerUnit: 3000.0,
        totalValue: 15000.0,
        timestamp: DateTime(2026, 3, 1, 10, 0, 0),
      );

      final json = transaction.toJson();

      expect(json['id'], '456');
      expect(json['type'], 'sell');
      expect(json['amount'], 5.0);
      expect(json['totalValue'], 15000.0);
    });

    test('toJson and fromJson are symmetric', () {
      final original = Transaction(
        id: '789',
        currencyId: 'bitcoin',
        currencyName: 'Bitcoin',
        currencySymbol: 'BTC',
        currencyImage: 'img.png',
        type: TransactionType.buy,
        amount: 1.5,
        pricePerUnit: 48000.0,
        totalValue: 72000.0,
        timestamp: DateTime(2026, 3, 5, 14, 30, 0),
      );

      final json = original.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.currencyId, original.currencyId);
      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
      expect(restored.pricePerUnit, original.pricePerUnit);
      expect(restored.totalValue, original.totalValue);
    });

    test('TransactionType enum has buy and sell', () {
      expect(TransactionType.values.length, 2);
      expect(TransactionType.values, contains(TransactionType.buy));
      expect(TransactionType.values, contains(TransactionType.sell));
    });
  });
}
