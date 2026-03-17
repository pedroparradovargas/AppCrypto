import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromJson crea instancia correctamente', () {
      final json = {
        'uid': 'test-uid-123',
        'email': 'test@email.com',
        'displayName': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
        'biometricRegistered': true,
        'createdAt': '2026-01-01T00:00:00.000',
        'lastLogin': '2026-03-12T10:00:00.000',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.uid, 'test-uid-123');
      expect(profile.email, 'test@email.com');
      expect(profile.displayName, 'Test User');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.biometricRegistered, true);
      expect(profile.createdAt, DateTime.parse('2026-01-01T00:00:00.000'));
      expect(profile.lastLogin, DateTime.parse('2026-03-12T10:00:00.000'));
    });

    test('fromJson maneja valores nulos con defaults', () {
      final json = <String, dynamic>{};

      final profile = UserProfile.fromJson(json);

      expect(profile.uid, '');
      expect(profile.email, '');
      expect(profile.displayName, '');
      expect(profile.photoUrl, isNull);
      expect(profile.biometricRegistered, false);
    });

    test('toJson produce JSON correcto', () {
      final profile = UserProfile(
        uid: 'uid-1',
        email: 'user@test.com',
        displayName: 'User Test',
        biometricRegistered: false,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime(2026, 3, 12),
      );

      final json = profile.toJson();

      expect(json['uid'], 'uid-1');
      expect(json['email'], 'user@test.com');
      expect(json['displayName'], 'User Test');
      expect(json['biometricRegistered'], false);
      expect(json['photoUrl'], isNull);
    });

    test('toJson / fromJson son simetricos', () {
      final original = UserProfile(
        uid: 'uid-sym',
        email: 'sym@test.com',
        displayName: 'Sym User',
        photoUrl: 'https://photo.url',
        biometricRegistered: true,
        createdAt: DateTime(2026, 1, 15, 10, 30),
        lastLogin: DateTime(2026, 3, 12, 14, 0),
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.biometricRegistered, original.biometricRegistered);
    });

    test('copyWith actualiza campos correctamente', () {
      final profile = UserProfile(
        uid: 'uid-copy',
        email: 'copy@test.com',
        displayName: 'Copy User',
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime(2026, 3, 1),
      );

      final updated = profile.copyWith(
        displayName: 'Updated User',
        biometricRegistered: true,
      );

      expect(updated.displayName, 'Updated User');
      expect(updated.biometricRegistered, true);
      expect(updated.uid, profile.uid); // sin cambio
      expect(updated.email, profile.email); // sin cambio
    });
  });
}
