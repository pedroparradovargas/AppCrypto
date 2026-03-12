import 'dart:math';
import '../models/blockchain_wallet.dart';

/// Payment gateway service for handling deposits and withdrawals
class PaymentService {
  final Random _random = Random.secure();

  String _generateId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Create a payment intent for adding funds
  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
    required String paymentMethodId,
  }) async {
    // Demo payment intent
    return PaymentIntent(
      id: _generateId(),
      amount: amount,
      currency: currency,
      status: 'succeeded',
      clientSecret: 'pi_demo_${_generateId()}_secret_demo',
      createdAt: DateTime.now(),
    );
  }

  /// Add payment method (card)
  Future<PaymentMethod> addCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
  }) async {
    // Clean card number
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    // Validate card number
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      throw Exception('Invalid card number length');
    }

    // Validate using Luhn algorithm
    if (!_isValidLuhn(cleanNumber)) {
      throw Exception('Invalid card number (failed Luhn check)');
    }

    // Validate expiry date
    final now = DateTime.now();
    final expMonth = int.tryParse(expiryMonth);
    final expYear = int.tryParse(expiryYear);

    if (expMonth == null || expMonth < 1 || expMonth > 12) {
      throw Exception('Invalid expiry month');
    }

    if (expYear == null) {
      throw Exception('Invalid expiry year');
    }

    // Convert 2-digit year to 4-digit
    final fullYear = expYear < 100 ? 2000 + expYear : expYear;
    final expiryDate = DateTime(fullYear, expMonth + 1);
    if (expiryDate.isBefore(now)) {
      throw Exception('Card has expired');
    }

    // Validate CVC
    if (cvc.length < 3 || cvc.length > 4) {
      throw Exception('Invalid CVC length');
    }

    // Demo payment method
    final last4 = cleanNumber.substring(cleanNumber.length - 4);
    final brand = _detectCardBrand(cleanNumber);

    return PaymentMethod(
      id: _generateId(),
      type: 'card',
      last4: last4,
      brand: brand,
      isDefault: false,
    );
  }

  /// Validate card number using Luhn algorithm
  bool _isValidLuhn(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Detect card brand from number
  String _detectCardBrand(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'Amex';
    if (number.startsWith('6')) return 'Discover';
    return 'Unknown';
  }

  /// Get saved payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    // In production, fetch from your backend or Stripe
    // Demo: return empty list
    return [];
  }

  /// Delete payment method
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    return true;
  }

  /// Deposit funds (fiat to wallet)
  Future<DepositResult> deposit({
    required double amount,
    required String paymentMethodId,
  }) async {
    try {
      final intent = await createPaymentIntent(
        amount: amount,
        currency: 'usd',
        paymentMethodId: paymentMethodId,
      );

      return DepositResult(
        success: true,
        transactionId: intent.id,
        amount: amount,
        message: 'Deposit successful',
      );
    } catch (e) {
      return DepositResult(
        success: false,
        transactionId: '',
        amount: amount,
        message: 'Deposit failed: ${e.toString()}',
      );
    }
  }

  /// Withdraw funds (wallet to bank)
  Future<WithdrawResult> withdraw({
    required double amount,
    required String bankAccountId,
  }) async {
    // Demo implementation
    return WithdrawResult(
      success: true,
      transactionId: _generateId(),
      amount: amount,
      message: 'Withdrawal initiated successfully',
      estimatedArrival: DateTime.now().add(const Duration(days: 3)),
    );
  }

  /// Buy crypto with fiat
  Future<BuyCryptoResult> buyCrypto({
    required double fiatAmount,
    required String cryptoCurrency,
    required String walletAddress,
    required String paymentMethodId,
  }) async {
    // Demo: simulate successful purchase
    final cryptoAmount = fiatAmount / 50000; // Assume 1 crypto = $50,000

    return BuyCryptoResult(
      success: true,
      fiatAmount: fiatAmount,
      cryptoAmount: cryptoAmount,
      cryptoCurrency: cryptoCurrency,
      transactionHash: '0x${_generateId()}',
      message: 'Purchase successful',
    );
  }

  /// Sell crypto (crypto to fiat)
  Future<SellCryptoResult> sellCrypto({
    required double cryptoAmount,
    required String cryptoCurrency,
    required double exchangeRate,
    required String bankAccountId,
  }) async {
    final fiatAmount = cryptoAmount * exchangeRate;

    return SellCryptoResult(
      success: true,
      cryptoAmount: cryptoAmount,
      fiatAmount: fiatAmount,
      cryptoCurrency: cryptoCurrency,
      transactionHash: '0x${_generateId()}',
      message: 'Sale successful',
      estimatedArrival: DateTime.now().add(const Duration(days: 3)),
    );
  }
}

/// Payment intent model
class PaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String clientSecret;
  final DateTime createdAt;

  PaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.clientSecret,
    required this.createdAt,
  });
}

/// Deposit result
class DepositResult {
  final bool success;
  final String transactionId;
  final double amount;
  final String message;

  DepositResult({
    required this.success,
    required this.transactionId,
    required this.amount,
    required this.message,
  });
}

/// Withdraw result
class WithdrawResult {
  final bool success;
  final String transactionId;
  final double amount;
  final String message;
  final DateTime estimatedArrival;

  WithdrawResult({
    required this.success,
    required this.transactionId,
    required this.amount,
    required this.message,
    required this.estimatedArrival,
  });
}

/// Buy crypto result
class BuyCryptoResult {
  final bool success;
  final double fiatAmount;
  final double cryptoAmount;
  final String cryptoCurrency;
  final String transactionHash;
  final String message;

  BuyCryptoResult({
    required this.success,
    required this.fiatAmount,
    required this.cryptoAmount,
    required this.cryptoCurrency,
    required this.transactionHash,
    required this.message,
  });
}

/// Sell crypto result
class SellCryptoResult {
  final bool success;
  final double cryptoAmount;
  final double fiatAmount;
  final String cryptoCurrency;
  final String transactionHash;
  final String message;
  final DateTime estimatedArrival;

  SellCryptoResult({
    required this.success,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.cryptoCurrency,
    required this.transactionHash,
    required this.message,
    required this.estimatedArrival,
  });
}
