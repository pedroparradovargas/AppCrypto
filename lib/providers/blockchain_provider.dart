import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/blockchain_wallet.dart';
import '../services/blockchain_service.dart';
import '../services/payment_service.dart';

/// Provider for managing blockchain wallets and payment operations
class BlockchainProvider extends ChangeNotifier {
  final BlockchainService _blockchainService = BlockchainService();
  final PaymentService _paymentService = PaymentService();

  // Secure storage for sensitive wallet data
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Blockchain wallets
  List<BlockchainWallet> _wallets = [];
  BlockchainWallet? _selectedWallet;
  bool _isLoadingWallets = false;
  String? _error;

  // Payment methods
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoadingPaymentMethods = false;

  // Blockchain transactions
  List<BlockchainTransaction> _transactions = [];
  bool _isLoadingTransactions = false;

  // Network
  BlockchainNetwork _selectedNetwork = BlockchainNetwork.ethereum;

  // Getters
  List<BlockchainWallet> get wallets => _wallets;
  BlockchainWallet? get selectedWallet => _selectedWallet;
  bool get isLoadingWallets => _isLoadingWallets;
  String? get error => _error;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoadingPaymentMethods => _isLoadingPaymentMethods;
  List<BlockchainTransaction> get transactions => _transactions;
  bool get isLoadingTransactions => _isLoadingTransactions;
  BlockchainNetwork get selectedNetwork => _selectedNetwork;

  /// Initialize provider
  Future<void> initialize() async {
    await _loadWallets();
    await _loadPaymentMethods();
  }

  /// Load saved wallets
  Future<void> _loadWallets() async {
    try {
      final walletsJson = await _storage.read(key: 'blockchain_wallets');
      if (walletsJson != null) {
        final List<dynamic> data = jsonDecode(walletsJson);
        _wallets = data.map((w) => BlockchainWallet.fromJson(w)).toList();
      }
    } catch (e) {
      // Store error and reset wallets to empty list
      _error = 'Failed to load wallets: ${e.toString()}';
      _wallets = [];
      notifyListeners();
    }
  }

  /// Save wallets
  Future<void> _saveWallets() async {
    try {
      final walletsJson = jsonEncode(_wallets.map((w) => w.toJson()).toList());
      await _storage.write(key: 'blockchain_wallets', value: walletsJson);
    } catch (e) {
      _error = 'Failed to save wallets: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load payment methods
  Future<void> _loadPaymentMethods() async {
    _isLoadingPaymentMethods = true;
    notifyListeners();

    try {
      _paymentMethods = await _paymentService.getPaymentMethods();
    } catch (e) {
      _paymentMethods = [];
    }

    _isLoadingPaymentMethods = false;
    notifyListeners();
  }

  /// Generate a new blockchain wallet
  Future<BlockchainWallet?> generateWallet() async {
    _isLoadingWallets = true;
    _error = null;
    notifyListeners();

    try {
      final wallet = await _blockchainService.generateWallet(_selectedNetwork);
      _wallets.add(wallet);
      await _saveWallets();

      _isLoadingWallets = false;
      notifyListeners();
      return wallet;
    } catch (e) {
      _error = e.toString();
      _isLoadingWallets = false;
      notifyListeners();
      return null;
    }
  }

  /// Import wallet from mnemonic
  Future<BlockchainWallet?> importWallet(String mnemonic) async {
    _isLoadingWallets = true;
    _error = null;
    notifyListeners();

    try {
      final wallet = await _blockchainService.importFromMnemonic(
        mnemonic,
        _selectedNetwork,
      );
      _wallets.add(wallet);
      await _saveWallets();

      _isLoadingWallets = false;
      notifyListeners();
      return wallet;
    } catch (e) {
      _error = e.toString();
      _isLoadingWallets = false;
      notifyListeners();
      return null;
    }
  }

  /// Connect external wallet (MetaMask, etc.)
  Future<BlockchainWallet?> connectExternalWallet(String address) async {
    _isLoadingWallets = true;
    _error = null;
    notifyListeners();

    try {
      final wallet = await _blockchainService.connectExternalWallet(address);
      if (wallet != null) {
        _wallets.add(wallet);
        await _saveWallets();
      }

      _isLoadingWallets = false;
      notifyListeners();
      return wallet;
    } catch (e) {
      _error = e.toString();
      _isLoadingWallets = false;
      notifyListeners();
      return null;
    }
  }

  /// Select a wallet
  void selectWallet(BlockchainWallet? wallet) {
    _selectedWallet = wallet;
    notifyListeners();
  }

  /// Select network
  void selectNetwork(BlockchainNetwork network) {
    _selectedNetwork = network;
    notifyListeners();
  }

  /// Refresh wallet balance
  Future<void> refreshWalletBalance(BlockchainWallet wallet) async {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index >= 0) {
      final balance = await _blockchainService.getBalance(
        wallet,
        _selectedNetwork,
      );
      _wallets[index] = wallet.copyWith(balance: balance);
      notifyListeners();
    }
  }

  /// Delete wallet
  Future<void> deleteWallet(String walletId) async {
    _wallets.removeWhere((w) => w.id == walletId);
    if (_selectedWallet?.id == walletId) {
      _selectedWallet = null;
    }
    await _saveWallets();
    notifyListeners();
  }

  /// Add payment method (card)
  Future<PaymentMethod?> addPaymentMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
  }) async {
    try {
      final paymentMethod = await _paymentService.addCard(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: cvc,
      );
      _paymentMethods.add(paymentMethod);
      notifyListeners();
      return paymentMethod;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete payment method
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    final result = await _paymentService.deletePaymentMethod(paymentMethodId);
    if (result) {
      _paymentMethods.removeWhere((p) => p.id == paymentMethodId);
      notifyListeners();
    }
    return result;
  }

  /// Deposit funds
  Future<DepositResult?> deposit({
    required double amount,
    required String paymentMethodId,
  }) async {
    _isLoadingWallets = true;
    notifyListeners();

    try {
      final result = await _paymentService.deposit(
        amount: amount,
        paymentMethodId: paymentMethodId,
      );

      _isLoadingWallets = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoadingWallets = false;
      notifyListeners();
      return null;
    }
  }

  /// Withdraw funds
  Future<WithdrawResult?> withdraw({
    required double amount,
    required String bankAccountId,
  }) async {
    _isLoadingWallets = true;
    notifyListeners();

    try {
      final result = await _paymentService.withdraw(
        amount: amount,
        bankAccountId: bankAccountId,
      );

      _isLoadingWallets = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoadingWallets = false;
      notifyListeners();
      return null;
    }
  }

  /// Send blockchain transaction (buy/sell)
  Future<BlockchainTransaction?> sendTransaction({
    required String toAddress,
    required double amount,
    required String currency,
  }) async {
    if (_selectedWallet == null) {
      _error = 'No wallet selected';
      notifyListeners();
      return null;
    }

    _isLoadingTransactions = true;
    notifyListeners();

    try {
      final result = await _blockchainService.sendTransaction(
        fromWallet: _selectedWallet!,
        toAddress: toAddress,
        amount: amount,
        network: _selectedNetwork,
        currency: currency,
      );

      _transactions.insert(0, result);
      _isLoadingTransactions = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoadingTransactions = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _blockchainService.dispose();
    super.dispose();
  }
}
