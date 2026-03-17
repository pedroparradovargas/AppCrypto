import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/services/stripe_payment_service.dart';

void main() {
  group('StripeCustomer', () {
    test('fromJson crea cliente correctamente', () {
      final json = {
        'id': 'cus_abc123',
        'email': 'customer@test.com',
        'name': 'Test Customer',
        'created': 1710000000,
      };

      final customer = StripeCustomer.fromJson(json);

      expect(customer.id, 'cus_abc123');
      expect(customer.email, 'customer@test.com');
      expect(customer.name, 'Test Customer');
      expect(customer.createdAt, isNotNull);
    });

    test('fromJson maneja campos faltantes', () {
      final json = <String, dynamic>{};

      final customer = StripeCustomer.fromJson(json);

      expect(customer.id, '');
      expect(customer.email, '');
      expect(customer.name, isNull);
    });
  });

  group('StripeSetupIntent', () {
    test('fromJson parsea correctamente', () {
      final json = {
        'id': 'seti_abc',
        'client_secret': 'seti_abc_secret_xyz',
        'status': 'requires_payment_method',
      };

      final intent = StripeSetupIntent.fromJson(json);

      expect(intent.id, 'seti_abc');
      expect(intent.clientSecret, 'seti_abc_secret_xyz');
      expect(intent.status, 'requires_payment_method');
    });
  });

  group('StripePaymentIntent', () {
    test('fromJson crea payment intent correctamente', () {
      final json = {
        'id': 'pi_abc123',
        'amount': 5000,
        'currency': 'usd',
        'status': 'succeeded',
        'client_secret': 'pi_abc123_secret',
        'created': 1710000000,
      };

      final intent = StripePaymentIntent.fromJson(json);

      expect(intent.id, 'pi_abc123');
      expect(intent.amount, 5000);
      expect(intent.currency, 'usd');
      expect(intent.status, 'succeeded');
      expect(intent.clientSecret, 'pi_abc123_secret');
    });

    test('fromJson maneja valores por defecto', () {
      final json = <String, dynamic>{};

      final intent = StripePaymentIntent.fromJson(json);

      expect(intent.id, '');
      expect(intent.amount, 0);
      expect(intent.currency, 'usd');
      expect(intent.status, '');
    });
  });

  group('StripePaymentMethod', () {
    test('fromJson parsea metodo de pago con datos de tarjeta', () {
      final json = {
        'id': 'pm_abc',
        'type': 'card',
        'card': {
          'brand': 'visa',
          'last4': '4242',
          'exp_month': 12,
          'exp_year': 2027,
        },
      };

      final pm = StripePaymentMethod.fromJson(json);

      expect(pm.id, 'pm_abc');
      expect(pm.type, 'card');
      expect(pm.brand, 'visa');
      expect(pm.last4, '4242');
      expect(pm.expMonth, 12);
      expect(pm.expYear, 2027);
    });

    test('fromJson maneja card faltante', () {
      final json = {
        'id': 'pm_nocard',
        'type': 'card',
      };

      final pm = StripePaymentMethod.fromJson(json);

      expect(pm.brand, 'unknown');
      expect(pm.last4, '0000');
      expect(pm.expMonth, 0);
      expect(pm.expYear, 0);
    });
  });

  group('StripeDepositResult', () {
    test('crea resultado exitoso', () {
      final result = StripeDepositResult(
        success: true,
        paymentIntentId: 'pi_123',
        amount: 100.0,
        currency: 'usd',
        message: 'Deposito exitoso',
      );

      expect(result.success, true);
      expect(result.paymentIntentId, 'pi_123');
      expect(result.amount, 100.0);
      expect(result.message, 'Deposito exitoso');
    });

    test('crea resultado fallido', () {
      final result = StripeDepositResult(
        success: false,
        paymentIntentId: '',
        amount: 50.0,
        currency: 'usd',
        message: 'Tarjeta rechazada',
      );

      expect(result.success, false);
      expect(result.paymentIntentId, '');
      expect(result.message, 'Tarjeta rechazada');
    });
  });

  group('StripeRefund', () {
    test('fromJson parsea reembolso', () {
      final json = {
        'id': 're_abc',
        'amount': 2500,
        'status': 'succeeded',
        'payment_intent': 'pi_xyz',
      };

      final refund = StripeRefund.fromJson(json);

      expect(refund.id, 're_abc');
      expect(refund.amount, 2500);
      expect(refund.status, 'succeeded');
      expect(refund.paymentIntentId, 'pi_xyz');
    });
  });

  group('StripeException', () {
    test('toString produce formato correcto', () {
      final exception = StripeException('Card declined', 'insufficient_funds');

      expect(exception.message, 'Card declined');
      expect(exception.details, 'insufficient_funds');
      expect(exception.toString(),
          'StripeException: Card declined (insufficient_funds)');
    });
  });

  group('MercadoPagoPreference', () {
    test('fromJson parsea preferencia', () {
      final json = {
        'id': 'pref_123',
        'init_point': 'https://www.mercadopago.com/checkout/v1/redirect?pref_id=123',
        'sandbox_init_point':
            'https://sandbox.mercadopago.com/checkout/v1/redirect?pref_id=123',
      };

      final pref = MercadoPagoPreference.fromJson(json);

      expect(pref.id, 'pref_123');
      expect(pref.initPoint, contains('mercadopago.com'));
      expect(pref.sandboxInitPoint, contains('sandbox'));
    });
  });

  group('MercadoPagoPayment', () {
    test('fromJson parsea pago', () {
      final json = {
        'id': 12345,
        'status': 'approved',
        'status_detail': 'accredited',
        'transaction_amount': 50000.0,
        'currency_id': 'COP',
        'date_created': '2026-03-11T10:00:00.000-05:00',
      };

      final payment = MercadoPagoPayment.fromJson(json);

      expect(payment.id, '12345');
      expect(payment.status, 'approved');
      expect(payment.statusDetail, 'accredited');
      expect(payment.amount, 50000.0);
      expect(payment.currency, 'COP');
    });
  });

  group('PaymentException', () {
    test('toString produce formato correcto', () {
      final exception = PaymentException('Payment failed', 'timeout');

      expect(exception.toString(),
          'PaymentException: Payment failed (timeout)');
    });
  });

  group('StripePaymentService', () {
    test('se instancia correctamente', () {
      final service = StripePaymentService(
        baseUrl: 'https://api.example.com',
        publishableKey: 'pk_test_abc',
      );
      expect(service, isNotNull);
    });
  });

  group('MercadoPagoService', () {
    test('se instancia correctamente', () {
      final service = MercadoPagoService(
        baseUrl: 'https://api.example.com',
        accessToken: 'TEST-abc123',
      );
      expect(service, isNotNull);
    });
  });
}
