import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de backend para la gestion de usuarios, autenticacion y transacciones.
///
/// Implementa un cliente REST API completo para comunicarse con el servidor
/// backend. Todas las operaciones sensibles (autenticacion, transacciones,
/// gestion de billeteras) se delegan al backend.
///
/// Arquitectura:
/// - Autenticacion mediante JWT (JSON Web Tokens)
/// - Refresh tokens para sesiones persistentes
/// - Almacenamiento seguro de tokens con FlutterSecureStorage
/// - Interceptor de autorizacion automatico
/// - Manejo centralizado de errores
class BackendService {
  final String _baseUrl;
  final http.Client _httpClient;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Claves de almacenamiento
  static const _accessTokenKey = 'backend_access_token';
  static const _refreshTokenKey = 'backend_refresh_token';
  static const _userIdKey = 'backend_user_id';

  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  BackendService({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client();

  /// Inicializa el servicio cargando tokens guardados
  Future<void> initialize() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    _userId = await _storage.read(key: _userIdKey);
  }

  /// Indica si el usuario tiene sesion activa
  bool get isAuthenticated => _accessToken != null;

  /// ID del usuario autenticado
  String? get userId => _userId;

  /// Headers con autorizacion JWT
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Headers sin autorizacion (para login/register)
  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
      };

  // ==================== AUTENTICACION ====================

  /// Registro de nuevo usuario
  ///
  /// Crea una cuenta y retorna tokens de acceso.
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: _publicHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _saveTokens(authResponse);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw BackendException(
          error['message'] ?? 'Error al registrar usuario',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Error de conexion: $e', 0);
    }
  }

  /// Inicio de sesion
  ///
  /// Autentica al usuario con email y password, retorna JWT tokens.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _publicHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _saveTokens(authResponse);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw BackendException(
          error['message'] ?? 'Credenciales invalidas',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Error de conexion: $e', 0);
    }
  }

  /// Cierre de sesion
  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _httpClient.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: _authHeaders,
        );
      }
    } finally {
      await _clearTokens();
    }
  }

  /// Renueva el access token usando el refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/refresh'),
        headers: _publicHeaders,
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'] ?? _refreshToken;
        await _storage.write(key: _accessTokenKey, value: _accessToken);
        if (data['refreshToken'] != null) {
          await _storage.write(key: _refreshTokenKey, value: _refreshToken);
        }
        return true;
      } else {
        await _clearTokens();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el perfil del usuario autenticado
  Future<UserProfile> getProfile() async {
    final response = await _authenticatedRequest(
      'GET',
      '/api/users/profile',
    );
    return UserProfile.fromJson(response);
  }

  /// Actualiza el perfil del usuario
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await _authenticatedRequest(
      'PUT',
      '/api/users/profile',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return UserProfile.fromJson(response);
  }

  /// Cambia la contrasena del usuario
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authenticatedRequest(
      'PUT',
      '/api/users/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // ==================== TRANSACCIONES ====================

  /// Obtiene el historial de transacciones
  Future<List<BackendTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    };

    final query = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await _authenticatedRequest(
      'GET',
      '/api/transactions?$query',
    );

    final list = response['transactions'] as List;
    return list.map((t) => BackendTransaction.fromJson(t)).toList();
  }

  /// Registra una transaccion de compra/venta
  Future<BackendTransaction> createTransaction({
    required String type,
    required String cryptoCurrency,
    required double amount,
    required double pricePerUnit,
    required double totalValue,
    String? walletAddress,
  }) async {
    final response = await _authenticatedRequest(
      'POST',
      '/api/transactions',
      body: {
        'type': type,
        'cryptoCurrency': cryptoCurrency,
        'amount': amount,
        'pricePerUnit': pricePerUnit,
        'totalValue': totalValue,
        if (walletAddress != null) 'walletAddress': walletAddress,
      },
    );
    return BackendTransaction.fromJson(response);
  }

  /// Obtiene una transaccion por ID
  Future<BackendTransaction> getTransaction(String transactionId) async {
    final response = await _authenticatedRequest(
      'GET',
      '/api/transactions/$transactionId',
    );
    return BackendTransaction.fromJson(response);
  }

  // ==================== BILLETERAS ====================

  /// Registra una billetera en el backend
  Future<Map<String, dynamic>> registerWallet({
    required String address,
    required String network,
    String? label,
  }) async {
    return await _authenticatedRequest(
      'POST',
      '/api/wallets',
      body: {
        'address': address,
        'network': network,
        if (label != null) 'label': label,
      },
    );
  }

  /// Obtiene las billeteras del usuario
  Future<List<Map<String, dynamic>>> getWallets() async {
    final response = await _authenticatedRequest(
      'GET',
      '/api/wallets',
    );
    return (response['wallets'] as List).cast<Map<String, dynamic>>();
  }

  /// Elimina una billetera del backend
  Future<void> deleteWallet(String walletId) async {
    await _authenticatedRequest(
      'DELETE',
      '/api/wallets/$walletId',
    );
  }

  // ==================== PORTFOLIO ====================

  /// Obtiene el portfolio del usuario (balances y posiciones)
  Future<Map<String, dynamic>> getPortfolio() async {
    return await _authenticatedRequest(
      'GET',
      '/api/portfolio',
    );
  }

  /// Obtiene el historial de balance del usuario
  Future<List<Map<String, dynamic>>> getBalanceHistory({
    String period = '7d',
  }) async {
    final response = await _authenticatedRequest(
      'GET',
      '/api/portfolio/history?period=$period',
    );
    return (response['history'] as List).cast<Map<String, dynamic>>();
  }

  // ==================== METODOS PRIVADOS ====================

  /// Realiza una peticion autenticada con manejo automatico de token refresh
  Future<dynamic> _authenticatedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    // Intentar la peticion
    var response = await _makeRequest(method, path, body: body);

    // Si el token expiro, intentar refresh
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await _makeRequest(method, path, body: body);
      } else {
        throw BackendException('Sesion expirada. Inicia sesion nuevamente.', 401);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      final error = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'message': 'Error desconocido'};
      throw BackendException(
        error['message'] ?? 'Error del servidor',
        response.statusCode,
      );
    }
  }

  /// Ejecuta una peticion HTTP
  Future<http.Response> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    switch (method) {
      case 'GET':
        return await _httpClient.get(uri, headers: _authHeaders);
      case 'POST':
        return await _httpClient.post(
          uri,
          headers: _authHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await _httpClient.put(
          uri,
          headers: _authHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await _httpClient.delete(uri, headers: _authHeaders);
      default:
        throw BackendException('Metodo HTTP no soportado: $method', 0);
    }
  }

  /// Guarda los tokens de autenticacion de forma segura
  Future<void> _saveTokens(AuthResponse auth) async {
    _accessToken = auth.accessToken;
    _refreshToken = auth.refreshToken;
    _userId = auth.userId;

    await _storage.write(key: _accessTokenKey, value: _accessToken);
    await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    await _storage.write(key: _userIdKey, value: _userId);
  }

  /// Limpia los tokens almacenados
  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  void dispose() {
    _httpClient.close();
  }
}

// ==================== Modelos ====================

class AuthResponse {
  final String userId;
  final String email;
  final String name;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  AuthResponse({
    required this.userId,
    required this.email,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] ?? json['user']?['id'] ?? '',
      email: json['email'] ?? json['user']?['email'] ?? '',
      name: json['name'] ?? json['user']?['name'] ?? '',
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'createdAt': createdAt.toIso8601String(),
      };
}

class BackendTransaction {
  final String id;
  final String userId;
  final String type;
  final String cryptoCurrency;
  final double amount;
  final double pricePerUnit;
  final double totalValue;
  final String status;
  final String? walletAddress;
  final String? txHash;
  final DateTime createdAt;

  BackendTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.cryptoCurrency,
    required this.amount,
    required this.pricePerUnit,
    required this.totalValue,
    required this.status,
    this.walletAddress,
    this.txHash,
    required this.createdAt,
  });

  factory BackendTransaction.fromJson(Map<String, dynamic> json) {
    return BackendTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      cryptoCurrency: json['cryptoCurrency'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      walletAddress: json['walletAddress'],
      txHash: json['txHash'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'cryptoCurrency': cryptoCurrency,
        'amount': amount,
        'pricePerUnit': pricePerUnit,
        'totalValue': totalValue,
        'status': status,
        'walletAddress': walletAddress,
        'txHash': txHash,
        'createdAt': createdAt.toIso8601String(),
      };
}

class BackendException implements Exception {
  final String message;
  final int statusCode;

  BackendException(this.message, this.statusCode);

  @override
  String toString() => 'BackendException($statusCode): $message';
}
