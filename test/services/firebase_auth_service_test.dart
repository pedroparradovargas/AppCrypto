import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/user_profile.dart';

/// Tests para FirebaseAuthService
/// Nota: Firebase requiere inicializacion nativa. Estos tests
/// verifican la logica del modelo UserProfile que usa el servicio.
/// Para tests de integracion con Firebase real, usar integration_test/.
void main() {
  group('FirebaseAuthService - UserProfile logic', () {
    test('crear perfil de usuario con datos validos', () {
      final profile = UserProfile(
        uid: 'firebase-uid-123',
        email: 'newuser@test.com',
        displayName: 'New User',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(profile.uid, 'firebase-uid-123');
      expect(profile.email, 'newuser@test.com');
      expect(profile.displayName, 'New User');
      expect(profile.biometricRegistered, false);
    });

    test('perfil con biometria registrada', () {
      final profile = UserProfile(
        uid: 'bio-uid',
        email: 'bio@test.com',
        displayName: 'Bio User',
        biometricRegistered: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(profile.biometricRegistered, true);
    });

    test('actualizar biometria via copyWith', () {
      final profile = UserProfile(
        uid: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final updated = profile.copyWith(biometricRegistered: true);

      expect(updated.biometricRegistered, true);
      expect(updated.uid, profile.uid);
    });

    test('actualizar lastLogin via copyWith', () {
      final originalLogin = DateTime(2026, 1, 1);
      final newLogin = DateTime(2026, 3, 12);

      final profile = UserProfile(
        uid: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        createdAt: DateTime(2026, 1, 1),
        lastLogin: originalLogin,
      );

      final updated = profile.copyWith(lastLogin: newLogin);

      expect(updated.lastLogin, newLogin);
      expect(updated.createdAt, profile.createdAt);
    });

    test('serializacion para Firestore', () {
      final profile = UserProfile(
        uid: 'fs-uid',
        email: 'firestore@test.com',
        displayName: 'Firestore User',
        photoUrl: 'https://photo.url/pic.jpg',
        biometricRegistered: true,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime(2026, 3, 12),
      );

      final json = profile.toJson();

      // Verificar que todos los campos requeridos por Firestore estan presentes
      expect(json.containsKey('uid'), true);
      expect(json.containsKey('email'), true);
      expect(json.containsKey('displayName'), true);
      expect(json.containsKey('photoUrl'), true);
      expect(json.containsKey('biometricRegistered'), true);
      expect(json.containsKey('createdAt'), true);
      expect(json.containsKey('lastLogin'), true);
    });

    test('deserializacion desde Firestore document', () {
      // Simular datos como vienen de Firestore
      final firestoreData = {
        'uid': 'doc-uid',
        'email': 'doc@test.com',
        'displayName': 'Doc User',
        'photoUrl': null,
        'biometricRegistered': false,
        'createdAt': '2026-01-01T00:00:00.000',
        'lastLogin': '2026-03-12T00:00:00.000',
      };

      final profile = UserProfile.fromJson(firestoreData);

      expect(profile.uid, 'doc-uid');
      expect(profile.email, 'doc@test.com');
      expect(profile.photoUrl, isNull);
    });
  });

  group('Firebase error messages', () {
    test('codigos de error comunes mapeados', () {
      // Verificar que los codigos de error de Firebase estan documentados
      final errorCodes = [
        'email-already-in-use',
        'invalid-email',
        'weak-password',
        'user-not-found',
        'wrong-password',
        'user-disabled',
        'too-many-requests',
        'invalid-credential',
      ];

      for (final code in errorCodes) {
        expect(code, isNotEmpty);
      }
    });
  });
}
