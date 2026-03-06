import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../services/crypto_service.dart';

class CryptoProvider extends ChangeNotifier {
  final CryptoService _cryptoService = CryptoService();

  // Market data
  List<Currency> _currencies = [];
  List<Currency> _filteredCurrencies = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // User data
  Wallet _wallet = Wallet();
  List<Transaction> _transactions = [];

  // Current selected currency for detail view
  Currency? _selectedCurrency;
  List<double> _historicalPrices = [];
  bool _isLoadingHistorical = false;

  // Getters
  List<Currency> get currencies =>
      _searchQuery.isEmpty ? _currencies : _filteredCurrencies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Wallet get wallet => _wallet;
  List<Transaction> get transactions => _transactions;
  Currency? get selectedCurrency => _selectedCurrency;
  List<double> get historicalPrices => _historicalPrices;
  bool get isLoadingHistorical => _isLoadingHistorical;

  // Initialize provider
  Future<void> initialize() async {
    await _loadWallet();
    await _loadTransactions();
    await fetchCurrencies();
  }

  // Fetch all currencies
  Future<void> fetchCurrencies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currencies = await _cryptoService.getTopCurrencies(perPage: 100);
      _applySearch();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search currencies
  void searchCurrencies(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredCurrencies = _currencies;
    } else {
      final queryLower = _searchQuery.toLowerCase();
      _filteredCurrencies = _currencies
          .where((c) =>
              c.name.toLowerCase().contains(queryLower) ||
              c.symbol.toLowerCase().contains(queryLower))
          .toList();
    }
  }

  // Select currency for detail view
  Future<void> selectCurrency(Currency currency) async {
    _selectedCurrency = currency;
    notifyListeners();
    await loadHistoricalPrices(currency.id);
  }

  // Load historical prices for chart
  Future<void> loadHistoricalPrices(String currencyId, {int days = 7}) async {
    _isLoadingHistorical = true;
    notifyListeners();

    try {
      _historicalPrices = await _cryptoService.getHistoricalPrices(
        currencyId,
        days: days,
      );
    } catch (e) {
      _historicalPrices = [];
    }

    _isLoadingHistorical = false;
    notifyListeners();
  }

  // Buy cryptocurrency
  Future<bool> buyCurrency(Currency currency, double amount) async {
    final totalCost = amount * currency.currentPrice;

    // Check if user has enough USD balance
    if (totalCost > _wallet.usdBalance) {
      return false;
    }

    // Create transaction
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currencyId: currency.id,
      currencyName: currency.name,
      currencySymbol: currency.symbol,
      currencyImage: currency.image,
      type: TransactionType.buy,
      amount: amount,
      pricePerUnit: currency.currentPrice,
      totalValue: totalCost,
      timestamp: DateTime.now(),
    );

    // Update wallet
    _wallet = _wallet.copyWith(
      usdBalance: _wallet.usdBalance - totalCost,
    );

    // Update or add currency to wallet
    final existingIndex = _wallet.items.indexWhere(
      (item) => item.currencyId == currency.id,
    );

    if (existingIndex >= 0) {
      // Update existing item with weighted average price
      final existing = _wallet.items[existingIndex];
      final newAmount = existing.amount + amount;
      final newAvgPrice = ((existing.amount * existing.averageBuyPrice) +
              (amount * currency.currentPrice)) /
          newAmount;

      final updatedItems = List<WalletItem>.from(_wallet.items);
      updatedItems[existingIndex] = existing.copyWith(
        amount: newAmount,
        averageBuyPrice: newAvgPrice,
      );
      _wallet = _wallet.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = WalletItem(
        currencyId: currency.id,
        name: currency.name,
        symbol: currency.symbol,
        image: currency.image,
        amount: amount,
        averageBuyPrice: currency.currentPrice,
      );
      _wallet = _wallet.copyWith(
        items: [..._wallet.items, newItem],
      );
    }

    // Add transaction
    _transactions.insert(0, transaction);

    // Save data
    await _saveWallet();
    await _saveTransactions();

    notifyListeners();
    return true;
  }

  // Sell cryptocurrency
  Future<bool> sellCurrency(Currency currency, double amount) async {
    // Check if user has enough of this currency
    final walletItem = _wallet.items.firstWhere(
      (item) => item.currencyId == currency.id,
      orElse: () => WalletItem(
        currencyId: '',
        name: '',
        symbol: '',
        image: '',
        amount: 0,
        averageBuyPrice: 0,
      ),
    );

    if (walletItem.amount < amount) {
      return false;
    }

    final totalValue = amount * currency.currentPrice;

    // Create transaction
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currencyId: currency.id,
      currencyName: currency.name,
      currencySymbol: currency.symbol,
      currencyImage: currency.image,
      type: TransactionType.sell,
      amount: amount,
      pricePerUnit: currency.currentPrice,
      totalValue: totalValue,
      timestamp: DateTime.now(),
    );

    // Update wallet
    final updatedItems = _wallet.items
        .map((item) {
          if (item.currencyId == currency.id) {
            final newAmount = item.amount - amount;
            if (newAmount <= 0) {
              return null; // Mark for removal
            }
            return item.copyWith(amount: newAmount);
          }
          return item;
        })
        .whereType<WalletItem>()
        .toList();

    _wallet = _wallet.copyWith(
      items: updatedItems,
      usdBalance: _wallet.usdBalance + totalValue,
    );

    // Add transaction
    _transactions.insert(0, transaction);

    // Save data
    await _saveWallet();
    await _saveTransactions();

    notifyListeners();
    return true;
  }

  // Get wallet item for a specific currency
  WalletItem? getWalletItem(String currencyId) {
    try {
      return _wallet.items.firstWhere(
        (item) => item.currencyId == currencyId,
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate profit/loss for a wallet item
  double calculateProfitLoss(WalletItem item, double currentPrice) {
    return (currentPrice - item.averageBuyPrice) * item.amount;
  }

  // Calculate profit/loss percentage for a wallet item
  double calculateProfitLossPercentage(WalletItem item, double currentPrice) {
    if (item.averageBuyPrice == 0) return 0;
    return ((currentPrice - item.averageBuyPrice) / item.averageBuyPrice) * 100;
  }

  // Persist wallet data
  Future<void> _saveWallet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet', jsonEncode(_wallet.toJson()));
  }

  // Load wallet data
  Future<void> _loadWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final walletJson = prefs.getString('wallet');
    if (walletJson != null) {
      try {
        _wallet = Wallet.fromJson(jsonDecode(walletJson));
      } catch (e) {
        _wallet = Wallet();
      }
    }
  }

  // Persist transactions
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = jsonEncode(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsJson);
  }

  // Load transactions
  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      try {
        final List<dynamic> data = jsonDecode(transactionsJson);
        _transactions = data.map((t) => Transaction.fromJson(t)).toList();
      } catch (e) {
        _transactions = [];
      }
    }
  }

  // Reset demo (clear all data)
  Future<void> resetDemo() async {
    _wallet = Wallet();
    _transactions = [];
    await _saveWallet();
    await _saveTransactions();
    notifyListeners();
  }
}
