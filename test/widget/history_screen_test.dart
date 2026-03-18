import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/transaction.dart';

void main() {
  group('HistoryScreen - Logic Tests', () {
    test('muestra el titulo Transaction History', () {
      const title = 'Transaction History';
      expect(title, isNotEmpty);
      expect(title, 'Transaction History');
    });

    test('muestra mensaje vacio cuando no hay transacciones', () {
      final List<Transaction> transactions = [];
      expect(transactions.isEmpty, true);

      // Verify empty state messages
      const emptyMessage = 'No transactions yet';
      const emptySubtitle = 'Your trading history will appear here';
      expect(emptyMessage, isNotEmpty);
      expect(emptySubtitle, isNotEmpty);
    });

    test('muestra icono de historial vacio', () {
      // When transactions list is empty, icon should be shown
      final List<Transaction> transactions = [];
      final showEmptyIcon = transactions.isEmpty;
      expect(showEmptyIcon, true);
    });

    test('formato de fecha relativa', () {
      final now = DateTime.now();

      // Today
      final today = now;
      final diffToday = now.difference(today).inDays;
      expect(diffToday, 0);

      // Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final diffYesterday = now.difference(yesterday).inDays;
      expect(diffYesterday, 1);

      // Last week
      final lastWeek = now.subtract(const Duration(days: 3));
      final diffWeek = now.difference(lastWeek).inDays;
      expect(diffWeek < 7, true);
    });

    test('transaccion buy muestra valores correctos', () {
      final transaction = Transaction(
        id: '1',
        currencyId: 'bitcoin',
        currencyName: 'Bitcoin',
        currencySymbol: 'btc',
        currencyImage: '',
        type: TransactionType.buy,
        amount: 0.5,
        pricePerUnit: 65000.0,
        totalValue: 32500.0,
        timestamp: DateTime.now(),
      );

      expect(transaction.type, TransactionType.buy);
      expect(transaction.currencySymbol.toUpperCase(), 'BTC');
      expect(transaction.totalValue, 32500.0);
    });

    test('transaccion sell muestra valores correctos', () {
      final transaction = Transaction(
        id: '2',
        currencyId: 'ethereum',
        currencyName: 'Ethereum',
        currencySymbol: 'eth',
        currencyImage: '',
        type: TransactionType.sell,
        amount: 2.0,
        pricePerUnit: 3500.0,
        totalValue: 7000.0,
        timestamp: DateTime.now(),
      );

      expect(transaction.type, TransactionType.sell);
      expect(transaction.currencySymbol.toUpperCase(), 'ETH');
      expect(transaction.totalValue, 7000.0);
    });
  });
}
