import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/services/backend_service.dart';

void main() {
  group('AuthResponse', () {
    test('fromJson parsea respuesta correctamente', () {
      final json = {
        'userId': 'user_123',
        'email': 'test@example.com',
        'name': 'Test User',
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.token',
        'refreshToken': 'refresh_abc123',
        'expiresAt': '2026-12-31T23:59:59.000Z',
      };

      final auth = AuthResponse.fromJson(json);

      expect(auth.userId, 'user_123');
      expect(auth.email, 'test@example.com');
      expect(auth.name, 'Test User');
      expect(auth.accessToken, 'eyJhbGciOiJIUzI1NiJ9.token');
      expect(auth.refreshToken, 'refresh_abc123');
      expect(auth.expiresAt.year, 2026);
    });

    test('fromJson maneja formato alternativo con user anidado', () {
      final json = {
        'user': {
          'id': 'user_456',
          'email': 'alt@example.com',
          'name': 'Alt User',
        },
        'access_token': 'token_abc',
        'refresh_token': 'refresh_xyz',
      };

      final auth = AuthResponse.fromJson(json);

      expect(auth.userId, 'user_456');
      expect(auth.email, 'alt@example.com');
      expect(auth.accessToken, 'token_abc');
      expect(auth.refreshToken, 'refresh_xyz');
    });

    test('fromJson maneja campos faltantes', () {
      final json = <String, dynamic>{};

      final auth = AuthResponse.fromJson(json);

      expect(auth.userId, '');
      expect(auth.email, '');
      expect(auth.accessToken, '');
    });
  });

  group('UserProfile', () {
    test('fromJson crea perfil correctamente', () {
      final json = {
        'id': 'profile_1',
        'email': 'user@crypto.com',
        'name': 'Crypto User',
        'phone': '+573001234567',
        'avatarUrl': 'https://example.com/avatar.png',
        'isVerified': true,
        'createdAt': '2026-01-15T10:30:00.000Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'profile_1');
      expect(profile.email, 'user@crypto.com');
      expect(profile.name, 'Crypto User');
      expect(profile.phone, '+573001234567');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.isVerified, true);
      expect(profile.createdAt.year, 2026);
    });

    test('toJson produce JSON correcto', () {
      final profile = UserProfile(
        id: 'p1',
        email: 'test@test.com',
        name: 'Test',
        phone: '+57300',
        isVerified: false,
        createdAt: DateTime(2026, 3, 11),
      );

      final json = profile.toJson();

      expect(json['id'], 'p1');
      expect(json['email'], 'test@test.com');
      expect(json['name'], 'Test');
      expect(json['phone'], '+57300');
      expect(json['isVerified'], false);
    });

    test('fromJson maneja valores opcionales null', () {
      final json = {
        'id': 'p2',
        'email': 'min@test.com',
        'name': 'Min User',
        'isVerified': false,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.phone, isNull);
      expect(profile.avatarUrl, isNull);
    });

    test('toJson/fromJson son simetricos', () {
      final original = UserProfile(
        id: 'sym_1',
        email: 'sym@test.com',
        name: 'Symmetry',
        phone: '+57123',
        avatarUrl: 'https://img.com/1.png',
        isVerified: true,
        createdAt: DateTime(2026, 6, 15, 14, 30),
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.phone, original.phone);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.isVerified, original.isVerified);
    });
  });

  group('BackendTransaction', () {
    test('fromJson crea transaccion correctamente', () {
      final json = {
        'id': 'tx_001',
        'userId': 'user_123',
        'type': 'buy',
        'cryptoCurrency': 'BTC',
        'amount': 0.5,
        'pricePerUnit': 65000.0,
        'totalValue': 32500.0,
        'status': 'completed',
        'walletAddress': '0x1234abcd',
        'txHash': '0xhash123',
        'createdAt': '2026-03-10T15:00:00.000Z',
      };

      final tx = BackendTransaction.fromJson(json);

      expect(tx.id, 'tx_001');
      expect(tx.userId, 'user_123');
      expect(tx.type, 'buy');
      expect(tx.cryptoCurrency, 'BTC');
      expect(tx.amount, 0.5);
      expect(tx.pricePerUnit, 65000.0);
      expect(tx.totalValue, 32500.0);
      expect(tx.status, 'completed');
      expect(tx.walletAddress, '0x1234abcd');
      expect(tx.txHash, '0xhash123');
    });

    test('toJson produce JSON correcto', () {
      final tx = BackendTransaction(
        id: 'tx_002',
        userId: 'user_456',
        type: 'sell',
        cryptoCurrency: 'ETH',
        amount: 2.0,
        pricePerUnit: 3500.0,
        totalValue: 7000.0,
        status: 'pending',
        createdAt: DateTime(2026, 3, 11),
      );

      final json = tx.toJson();

      expect(json['id'], 'tx_002');
      expect(json['type'], 'sell');
      expect(json['amount'], 2.0);
      expect(json['status'], 'pending');
      expect(json['walletAddress'], isNull);
    });

    test('fromJson maneja campos opcionales null', () {
      final json = {
        'id': 'tx_003',
        'userId': 'u1',
        'type': 'buy',
        'cryptoCurrency': 'BTC',
        'amount': 1,
        'pricePerUnit': 50000,
        'totalValue': 50000,
        'status': 'completed',
      };

      final tx = BackendTransaction.fromJson(json);

      expect(tx.walletAddress, isNull);
      expect(tx.txHash, isNull);
    });

    test('toJson/fromJson son simetricos', () {
      final original = BackendTransaction(
        id: 'sym_tx',
        userId: 'sym_u',
        type: 'buy',
        cryptoCurrency: 'SOL',
        amount: 10.0,
        pricePerUnit: 150.0,
        totalValue: 1500.0,
        status: 'completed',
        walletAddress: '0xwallet',
        txHash: '0xtxhash',
        createdAt: DateTime(2026, 3, 11, 10, 0),
      );

      final json = original.toJson();
      final restored = BackendTransaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
      expect(restored.cryptoCurrency, original.cryptoCurrency);
      expect(restored.walletAddress, original.walletAddress);
      expect(restored.txHash, original.txHash);
    });
  });

  group('BackendException', () {
    test('toString produce formato correcto', () {
      final exception = BackendException('Not found', 404);

      expect(exception.message, 'Not found');
      expect(exception.statusCode, 404);
      expect(exception.toString(), 'BackendException(404): Not found');
    });
  });

  group('BackendService', () {
    test('se instancia correctamente', () {
      final service = BackendService(baseUrl: 'https://api.example.com');
      expect(service, isNotNull);
      expect(service.isAuthenticated, false);
      expect(service.userId, isNull);
    });
  });
}
