import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio de pagos reales integrado con Stripe.
///
/// Implementa la integracion con la API de Stripe para:
/// - Crear clientes (Customers)
/// - Agregar metodos de pago (PaymentMethods)
/// - Crear intenciones de pago (PaymentIntents)
/// - Procesar depositos y retiros
///
/// Configuracion requerida:
/// - Stripe Secret Key (backend) y Publishable Key (frontend)
/// - Endpoint del backend para operaciones seguras
///
/// IMPORTANTE: En produccion, las operaciones con la Secret Key
/// deben ejecutarse en el backend, NUNCA en el cliente.
class StripePaymentService {
  final String _baseUrl;
  final String _publishableKey;
  final http.Client _httpClient;

  /// Headers de autorizacion para el backend
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_publishableKey',
      };

  StripePaymentService({
    required String baseUrl,
    required String publishableKey,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _publishableKey = publishableKey,
        _httpClient = httpClient ?? http.Client();

  /// Crea un cliente en Stripe
  ///
  /// Cada usuario de la app debe tener un Customer asociado en Stripe
  /// para poder guardar metodos de pago y procesar transacciones.
  Future<StripeCustomer> createCustomer({
    required String email,
    String? name,
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/payments/create-customer'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'name': name,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return StripeCustomer.fromJson(data);
      } else {
        throw StripeException(
          'Error al crear cliente: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Error de conexion al crear cliente', e.toString());
    }
  }

  /// Crea un SetupIntent para guardar un metodo de pago
  ///
  /// El SetupIntent permite tokenizar la tarjeta del usuario
  /// sin realizar un cobro inmediato.
  Future<StripeSetupIntent> createSetupIntent({
    required String customerId,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/payments/create-setup-intent'),
        headers: _headers,
        body: jsonEncode({
          'customerId': customerId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return StripeSetupIntent.fromJson(data);
      } else {
        throw StripeException(
          'Error al crear setup intent: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Error de conexion', e.toString());
    }
  }

  /// Crea un PaymentIntent para procesar un pago
  ///
  /// El PaymentIntent es el objeto principal de Stripe para manejar pagos.
  /// Soporta multiples metodos de pago y maneja la confirmacion automatica.
  Future<StripePaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
    String? paymentMethodId,
    String? description,
    Map<String, String>? metadata,
  }) async {
    try {
      // Stripe espera el monto en centavos (para USD)
      final amountInCents = (amount * 100).round();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/payments/create-payment-intent'),
        headers: _headers,
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'customerId': customerId,
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
          if (description != null) 'description': description,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return StripePaymentIntent.fromJson(data);
      } else {
        throw StripeException(
          'Error al crear payment intent: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Error de conexion', e.toString());
    }
  }

  /// Confirma un PaymentIntent
  ///
  /// Despues de que el usuario ingresa los datos de su tarjeta,
  /// se confirma el pago con el metodo de pago seleccionado.
  Future<StripePaymentIntent> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/payments/confirm-payment'),
        headers: _headers,
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StripePaymentIntent.fromJson(data);
      } else {
        throw StripeException(
          'Error al confirmar pago: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Error de conexion', e.toString());
    }
  }

  /// Obtiene los metodos de pago guardados de un cliente
  Future<List<StripePaymentMethod>> getPaymentMethods({
    required String customerId,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(
            '$_baseUrl/api/payments/payment-methods?customerId=$customerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((pm) => StripePaymentMethod.fromJson(pm)).toList();
      } else {
        throw StripeException(
          'Error al obtener metodos de pago: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Error de conexion', e.toString());
    }
  }

  /// Elimina un metodo de pago
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse(
            '$_baseUrl/api/payments/payment-methods/$paymentMethodId'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw StripeException(
          'Error al eliminar metodo de pago', e.toString());
    }
  }

  /// Procesa un deposito completo (crear intent + confirmar)
  Future<StripeDepositResult> processDeposit({
    required double amount,
    required String customerId,
    required String paymentMethodId,
    String currency = 'usd',
  }) async {
    try {
      // Crear payment intent
      final intent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
        paymentMethodId: paymentMethodId,
        description: 'Deposito CryptoExchange',
      );

      // Confirmar pago
      final confirmedIntent = await confirmPayment(
        paymentIntentId: intent.id,
        paymentMethodId: paymentMethodId,
      );

      return StripeDepositResult(
        success: confirmedIntent.status == 'succeeded',
        paymentIntentId: confirmedIntent.id,
        amount: amount,
        currency: currency,
        message: confirmedIntent.status == 'succeeded'
            ? 'Deposito exitoso'
            : 'Pago pendiente de confirmacion',
      );
    } catch (e) {
      return StripeDepositResult(
        success: false,
        paymentIntentId: '',
        amount: amount,
        currency: currency,
        message: 'Error en el deposito: ${e.toString()}',
      );
    }
  }

  /// Crea un reembolso
  Future<StripeRefund> createRefund({
    required String paymentIntentId,
    double? amount,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/payments/refund'),
        headers: _headers,
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          if (amount != null) 'amount': (amount * 100).round(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StripeRefund.fromJson(data);
      } else {
        throw StripeException(
          'Error al crear reembolso: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Error de conexion', e.toString());
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Servicio de pagos con MercadoPago
///
/// Implementa la integracion con la API de MercadoPago para
/// mercados latinoamericanos (Colombia, Argentina, Mexico, etc.)
class MercadoPagoService {
  final String _baseUrl;
  final String _accessToken;
  final http.Client _httpClient;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

  MercadoPagoService({
    required String baseUrl,
    required String accessToken,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _accessToken = accessToken,
        _httpClient = httpClient ?? http.Client();

  /// Crea una preferencia de pago en MercadoPago
  ///
  /// La preferencia contiene los items a pagar y las URLs de retorno.
  Future<MercadoPagoPreference> createPreference({
    required double amount,
    required String title,
    required String description,
    required String payerEmail,
    String currency = 'COP',
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/payments/mercadopago/preference'),
        headers: _headers,
        body: jsonEncode({
          'items': [
            {
              'title': title,
              'description': description,
              'quantity': 1,
              'unit_price': amount,
              'currency_id': currency,
            }
          ],
          'payer': {'email': payerEmail},
          'back_urls': {
            'success': '$_baseUrl/payment/success',
            'failure': '$_baseUrl/payment/failure',
            'pending': '$_baseUrl/payment/pending',
          },
          'auto_return': 'approved',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MercadoPagoPreference.fromJson(data);
      } else {
        throw PaymentException(
          'Error al crear preferencia: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Error de conexion', e.toString());
    }
  }

  /// Consulta el estado de un pago
  Future<MercadoPagoPayment> getPaymentStatus(String paymentId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/payments/mercadopago/status/$paymentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MercadoPagoPayment.fromJson(data);
      } else {
        throw PaymentException(
          'Error al consultar pago: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Error de conexion', e.toString());
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

// ==================== Modelos Stripe ====================

class StripeCustomer {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;

  StripeCustomer({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
  });

  factory StripeCustomer.fromJson(Map<String, dynamic> json) {
    return StripeCustomer(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      createdAt: json['created'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000)
          : DateTime.now(),
    );
  }
}

class StripeSetupIntent {
  final String id;
  final String clientSecret;
  final String status;

  StripeSetupIntent({
    required this.id,
    required this.clientSecret,
    required this.status,
  });

  factory StripeSetupIntent.fromJson(Map<String, dynamic> json) {
    return StripeSetupIntent(
      id: json['id'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class StripePaymentIntent {
  final String id;
  final int amount;
  final String currency;
  final String status;
  final String clientSecret;
  final DateTime createdAt;

  StripePaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.clientSecret,
    required this.createdAt,
  });

  factory StripePaymentIntent.fromJson(Map<String, dynamic> json) {
    return StripePaymentIntent(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'usd',
      status: json['status'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      createdAt: json['created'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000)
          : DateTime.now(),
    );
  }
}

class StripePaymentMethod {
  final String id;
  final String type;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  StripePaymentMethod({
    required this.id,
    required this.type,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  factory StripePaymentMethod.fromJson(Map<String, dynamic> json) {
    final card = json['card'] ?? {};
    return StripePaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? 'card',
      brand: card['brand'] ?? 'unknown',
      last4: card['last4'] ?? '0000',
      expMonth: card['exp_month'] ?? 0,
      expYear: card['exp_year'] ?? 0,
    );
  }
}

class StripeDepositResult {
  final bool success;
  final String paymentIntentId;
  final double amount;
  final String currency;
  final String message;

  StripeDepositResult({
    required this.success,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.message,
  });
}

class StripeRefund {
  final String id;
  final int amount;
  final String status;
  final String paymentIntentId;

  StripeRefund({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentIntentId,
  });

  factory StripeRefund.fromJson(Map<String, dynamic> json) {
    return StripeRefund(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? '',
      paymentIntentId: json['payment_intent'] ?? '',
    );
  }
}

class StripeException implements Exception {
  final String message;
  final String details;

  StripeException(this.message, this.details);

  @override
  String toString() => 'StripeException: $message ($details)';
}

// ==================== Modelos MercadoPago ====================

class MercadoPagoPreference {
  final String id;
  final String initPoint;
  final String sandboxInitPoint;

  MercadoPagoPreference({
    required this.id,
    required this.initPoint,
    required this.sandboxInitPoint,
  });

  factory MercadoPagoPreference.fromJson(Map<String, dynamic> json) {
    return MercadoPagoPreference(
      id: json['id'] ?? '',
      initPoint: json['init_point'] ?? '',
      sandboxInitPoint: json['sandbox_init_point'] ?? '',
    );
  }
}

class MercadoPagoPayment {
  final String id;
  final String status;
  final String statusDetail;
  final double amount;
  final String currency;
  final DateTime createdAt;

  MercadoPagoPayment({
    required this.id,
    required this.status,
    required this.statusDetail,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory MercadoPagoPayment.fromJson(Map<String, dynamic> json) {
    return MercadoPagoPayment(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      statusDetail: json['status_detail'] ?? '',
      amount: (json['transaction_amount'] ?? 0).toDouble(),
      currency: json['currency_id'] ?? 'COP',
      createdAt: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : DateTime.now(),
    );
  }
}

class PaymentException implements Exception {
  final String message;
  final String details;

  PaymentException(this.message, this.details);

  @override
  String toString() => 'PaymentException: $message ($details)';
}
