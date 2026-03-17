import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/services/payment_service.dart';

void main() {
  late PaymentService paymentService;

  setUp(() {
    paymentService = PaymentService();
  });

  group('PaymentService - Card Validation', () {
    test('addCard validates card number length', () async {
      expect(
        () => paymentService.addCard(
          cardNumber: '123',
          expiryMonth: '12',
          expiryYear: '30',
          cvc: '123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid card number length'),
        )),
      );
    });

    test('addCard validates Luhn algorithm', () async {
      expect(
        () => paymentService.addCard(
          cardNumber: '4111111111111112', // Invalid Luhn
          expiryMonth: '12',
          expiryYear: '30',
          cvc: '123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Luhn'),
        )),
      );
    });

    test('addCard validates expiry month range', () async {
      expect(
        () => paymentService.addCard(
          cardNumber: '4111111111111111', // Valid Luhn
          expiryMonth: '13',
          expiryYear: '30',
          cvc: '123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid expiry month'),
        )),
      );
    });

    test('addCard validates expired card', () async {
      expect(
        () => paymentService.addCard(
          cardNumber: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '20', // Year 2020 - expired
          cvc: '123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('expired'),
        )),
      );
    });

    test('addCard validates CVC length', () async {
      expect(
        () => paymentService.addCard(
          cardNumber: '4111111111111111',
          expiryMonth: '12',
          expiryYear: '30',
          cvc: '12', // Too short
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid CVC'),
        )),
      );
    });

    test('addCard succeeds with valid card data', () async {
      final pm = await paymentService.addCard(
        cardNumber: '4111111111111111',
        expiryMonth: '12',
        expiryYear: '30',
        cvc: '123',
      );

      expect(pm.last4, '1111');
      expect(pm.brand, 'Visa');
      expect(pm.type, 'card');
    });

    test('addCard detects Visa brand', () async {
      final pm = await paymentService.addCard(
        cardNumber: '4111111111111111',
        expiryMonth: '12',
        expiryYear: '30',
        cvc: '123',
      );
      expect(pm.brand, 'Visa');
    });

    test('addCard detects Mastercard brand', () async {
      final pm = await paymentService.addCard(
        cardNumber: '5500000000000004',
        expiryMonth: '12',
        expiryYear: '30',
        cvc: '123',
      );
      expect(pm.brand, 'Mastercard');
    });

    test('addCard accepts card with spaces', () async {
      final pm = await paymentService.addCard(
        cardNumber: '4111 1111 1111 1111',
        expiryMonth: '12',
        expiryYear: '30',
        cvc: '123',
      );
      expect(pm.last4, '1111');
    });
  });

  group('PaymentService - Operations', () {
    test('deposit returns successful result', () async {
      final result = await paymentService.deposit(
        amount: 100.0,
        paymentMethodId: 'pm-1',
      );

      expect(result.success, true);
      expect(result.amount, 100.0);
      expect(result.transactionId, isNotEmpty);
    });

    test('withdraw returns successful result', () async {
      final result = await paymentService.withdraw(
        amount: 50.0,
        bankAccountId: 'bank-1',
      );

      expect(result.success, true);
      expect(result.amount, 50.0);
      expect(result.estimatedArrival.isAfter(DateTime.now()), true);
    });

    test('buyCrypto returns successful result', () async {
      final result = await paymentService.buyCrypto(
        fiatAmount: 1000.0,
        cryptoCurrency: 'BTC',
        walletAddress: '0xabc',
        paymentMethodId: 'pm-1',
      );

      expect(result.success, true);
      expect(result.fiatAmount, 1000.0);
      expect(result.cryptoAmount, greaterThan(0));
      expect(result.transactionHash, startsWith('0x'));
    });

    test('sellCrypto returns successful result', () async {
      final result = await paymentService.sellCrypto(
        cryptoAmount: 1.0,
        cryptoCurrency: 'BTC',
        exchangeRate: 50000.0,
        bankAccountId: 'bank-1',
      );

      expect(result.success, true);
      expect(result.fiatAmount, 50000.0);
      expect(result.cryptoAmount, 1.0);
    });

    test('getPaymentMethods returns empty list', () async {
      final methods = await paymentService.getPaymentMethods();
      expect(methods, isEmpty);
    });

    test('deletePaymentMethod returns true', () async {
      final result = await paymentService.deletePaymentMethod('pm-1');
      expect(result, true);
    });

    test('createPaymentIntent returns succeeded status', () async {
      final intent = await paymentService.createPaymentIntent(
        amount: 100.0,
        currency: 'usd',
        paymentMethodId: 'pm-1',
      );

      expect(intent.status, 'succeeded');
      expect(intent.amount, 100.0);
      expect(intent.currency, 'usd');
    });
  });
}
