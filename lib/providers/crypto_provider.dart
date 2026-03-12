import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:candlesticks/candlesticks.dart';
import '../models/currency.dart';
import '../models/wallet.dart';
import '../models/transaction.dart' as app_models;
import '../models/candle_data.dart';
import '../services/crypto_service.dart';
import '../main.dart' show firebaseInitialized;

class CryptoProvider extends ChangeNotifier {
  final CryptoService _cryptoService = CryptoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Market data
  List<Currency> _currencies = [];
  List<Currency> _filteredCurrencies = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // User data
  Wallet _wallet = Wallet();
  List<app_models.Transaction> _transactions = [];

  // Current selected currency for detail view
  Currency? _selectedCurrency;
  List<double> _historicalPrices = [];
  bool _isLoadingHistorical = false;

  // Candlestick chart data (Binance style)
  List<Candle> _candles = [];
  bool _isLoadingCandles = false;

  // Getters
  List<Currency> get currencies =>
      _searchQuery.isEmpty ? _currencies : _filteredCurrencies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Wallet get wallet => _wallet;
  List<app_models.Transaction> get transactions => _transactions;
  Currency? get selectedCurrency => _selectedCurrency;
  List<double> get historicalPrices => _historicalPrices;
  bool get isLoadingHistorical => _isLoadingHistorical;
  List<Candle> get candles => _candles;
  bool get isLoadingCandles => _isLoadingCandles;

  /// UID del usuario actual en Firebase Auth
  String? get _uid => _auth.currentUser?.uid;

  /// Referencia al documento del wallet del usuario
  DocumentReference? get _walletDoc =>
      _uid != null ? _firestore.collection('users').doc(_uid).collection('data').doc('wallet') : null;

  /// Referencia a la coleccion de transacciones del usuario
  CollectionReference? get _transactionsCol =>
      _uid != null ? _firestore.collection('users').doc(_uid).collection('transactions') : null;

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

  // Load candlestick data (OHLC) for Binance-style charts
  Future<void> loadCandleData(String currencyId, {int days = 7}) async {
    _isLoadingCandles = true;
    notifyListeners();

    try {
      final ohlcData = await _cryptoService.getOHLCData(
        currencyId,
        days: days,
      );

      // Obtener volumenes
      List<List<dynamic>> volumeData = [];
      try {
        volumeData = await _cryptoService.getVolumeData(
          currencyId,
          days: days,
        );
      } catch (_) {
        // Si falla el volumen, continuar sin el
      }

      // Parsear datos OHLC
      final candleDataList = ohlcData
          .map((data) => CandleData.fromCoinGeckoOHLC(data))
          .toList();

      // Merge volumes por timestamp mas cercano
      if (volumeData.isNotEmpty) {
        for (int i = 0; i < candleDataList.length; i++) {
          final candleTime = candleDataList[i].date.millisecondsSinceEpoch;
          double closestVolume = 0;
          int minDiff = double.maxFinite.toInt();

          for (final vol in volumeData) {
            final volTime = vol[0] as int;
            final diff = (volTime - candleTime).abs();
            if (diff < minDiff) {
              minDiff = diff;
              closestVolume = (vol[1] as num).toDouble();
            }
          }

          candleDataList[i] = candleDataList[i].copyWith(volume: closestVolume);
        }
      }

      // Convertir a Candle del paquete candlesticks
      _candles = candleDataList.map((c) => Candle(
        date: c.date,
        open: c.open,
        high: c.high,
        low: c.low,
        close: c.close,
        volume: c.volume,
      )).toList();

      // Ordenar por fecha descendente (el paquete lo requiere asi)
      _candles.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _candles = [];
    }

    _isLoadingCandles = false;
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
    final transaction = app_models.Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currencyId: currency.id,
      currencyName: currency.name,
      currencySymbol: currency.symbol,
      currencyImage: currency.image,
      type: app_models.TransactionType.buy,
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

    // Save data to Firestore
    await _saveWallet();
    await _saveTransaction(transaction);

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
    final transaction = app_models.Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currencyId: currency.id,
      currencyName: currency.name,
      currencySymbol: currency.symbol,
      currencyImage: currency.image,
      type: app_models.TransactionType.sell,
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

    // Save data to Firestore
    await _saveWallet();
    await _saveTransaction(transaction);

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

  // ==================== FIRESTORE PERSISTENCE ====================

  // Save wallet to Firestore
  Future<void> _saveWallet() async {
    if (!firebaseInitialized || _walletDoc == null) return;

    try {
      await _walletDoc!.set(_wallet.toJson()).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error guardando wallet en Firestore: $e');
    }
  }

  // Load wallet from Firestore
  Future<void> _loadWallet() async {
    if (!firebaseInitialized || _walletDoc == null) return;

    try {
      final doc = await _walletDoc!.get().timeout(const Duration(seconds: 10));
      if (doc.exists && doc.data() != null) {
        _wallet = Wallet.fromJson(doc.data()! as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error cargando wallet desde Firestore: $e');
      _wallet = Wallet();
    }
  }

  // Save a single transaction to Firestore
  Future<void> _saveTransaction(app_models.Transaction transaction) async {
    if (!firebaseInitialized || _transactionsCol == null) return;

    try {
      await _transactionsCol!.doc(transaction.id).set(transaction.toJson())
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error guardando transaccion en Firestore: $e');
    }
  }

  // Load transactions from Firestore
  Future<void> _loadTransactions() async {
    if (!firebaseInitialized || _transactionsCol == null) return;

    try {
      final snapshot = await _transactionsCol!
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 10));

      _transactions = snapshot.docs
          .map((doc) => app_models.Transaction.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error cargando transacciones desde Firestore: $e');
      _transactions = [];
    }
  }

  // Reset all user data
  Future<void> resetDemo() async {
    _wallet = Wallet();
    _transactions = [];
    await _saveWallet();

    // Delete all transactions from Firestore
    if (firebaseInitialized && _transactionsCol != null) {
      try {
        final snapshot = await _transactionsCol!.get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error eliminando transacciones: $e');
      }
    }

    notifyListeners();
  }
}
