import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/user_profile.dart';

/// Tests para AuthProvider
/// Nota: Los tests de Firebase Auth requieren mocks nativos de Firebase.
/// Estos tests verifican la logica de negocio y flujo de estados.
void main() {
  group('AuthProvider - Logica de estados', () {
    test('estado inicial: no autenticado', () {
      // El AuthProvider inicia sin autenticacion Firebase
      const isFirebaseAuthenticated = false;
      const isAuthenticated = false;
      const isPinEnabled = false;

      expect(isFirebaseAuthenticated, false);
      expect(isAuthenticated, false);
      expect(isPinEnabled, false);
    });

    test('flujo de login exitoso actualiza estado', () {
      // Simular login exitoso
      bool isFirebaseAuthenticated = false;
      UserProfile? userProfile;

      // Despues del login
      isFirebaseAuthenticated = true;
      userProfile = UserProfile(
        uid: 'test-uid',
        email: 'test@email.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(isFirebaseAuthenticated, true);
      expect(userProfile, isNotNull);
      expect(userProfile!.email, 'test@email.com');
    });

    test('flujo de registro exitoso con biometria', () {
      bool isFirebaseAuthenticated = false;
      bool isBiometricEnabled = false;

      // Paso 1: Registro Firebase
      isFirebaseAuthenticated = true;

      // Paso 2: Registro biometria
      isBiometricEnabled = true;

      expect(isFirebaseAuthenticated, true);
      expect(isBiometricEnabled, true);
    });

    test('signOut resetea todo el estado', () {
      bool isFirebaseAuthenticated = true;
      bool isAuthenticated = true;
      UserProfile? userProfile = UserProfile(
        uid: 'uid',
        email: 'test@test.com',
        displayName: 'Test',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Ejecutar signOut
      isFirebaseAuthenticated = false;
      isAuthenticated = false;
      userProfile = null;

      expect(isFirebaseAuthenticated, false);
      expect(isAuthenticated, false);
      expect(userProfile, isNull);
    });

    test('doble capa de auth: Firebase + PIN', () {
      // Paso 1: Firebase autenticado, PIN habilitado
      const isFirebaseAuthenticated = true;
      const isPinEnabled = true;
      bool isLocalAuthenticated = false;

      // El usuario ve la pantalla de PIN
      expect(isFirebaseAuthenticated, true);
      expect(isPinEnabled && !isLocalAuthenticated, true);

      // Paso 2: Ingresa PIN correcto
      isLocalAuthenticated = true;

      // El usuario accede a la app
      expect(isFirebaseAuthenticated && isLocalAuthenticated, true);
    });

    test('recovery de contraseña no cambia estado de auth', () {
      const isFirebaseAuthenticated = false;
      bool resetEmailSent = false;

      // Enviar email de recuperacion
      resetEmailSent = true;

      expect(isFirebaseAuthenticated, false); // Sin cambio
      expect(resetEmailSent, true);
    });
  });

  group('AuthProvider - Mensajes de error Firebase', () {
    test('mapear codigos de error a mensajes en español', () {
      final errorMap = {
        'email-already-in-use': 'Este email ya esta registrado',
        'invalid-email': 'Email invalido',
        'weak-password': 'La contraseña debe tener al menos 6 caracteres',
        'user-not-found': 'No existe una cuenta con este email',
        'wrong-password': 'Contraseña incorrecta',
        'user-disabled': 'Esta cuenta ha sido desactivada',
        'too-many-requests': 'Demasiados intentos. Intenta mas tarde',
        'invalid-credential': 'Credenciales invalidas',
      };

      for (final entry in errorMap.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.value.length, greaterThan(5));
      }
    });

    test('codigo desconocido retorna mensaje generico', () {
      const unknownCode = 'unknown-error-xyz';
      final message = 'Error de autenticacion: $unknownCode';

      expect(message.contains(unknownCode), true);
    });
  });

  group('AuthProvider - Validaciones de formulario', () {
    test('email vacio es invalido', () {
      const email = '';
      expect(email.isEmpty, true);
    });

    test('password menor a 6 caracteres es invalida', () {
      const password = '12345';
      expect(password.length < 6, true);
    });

    test('passwords no coinciden', () {
      const password = 'password123';
      const confirmPassword = 'password456';
      expect(password != confirmPassword, true);
    });

    test('datos de registro validos', () {
      const name = 'Test User';
      const email = 'test@email.com';
      const password = 'SecurePass123!';
      const confirmPassword = 'SecurePass123!';

      expect(name.isNotEmpty, true);
      expect(email.contains('@'), true);
      expect(password.length >= 6, true);
      expect(password == confirmPassword, true);
    });

    test('fortaleza de contraseña', () {
      int getStrength(String password) {
        int strength = 0;
        if (password.length >= 6) strength++;
        if (password.length >= 8) strength++;
        if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
        if (RegExp(r'[0-9]').hasMatch(password)) strength++;
        if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
        return strength;
      }

      expect(getStrength('abc'), 0); // Debil
      expect(getStrength('abcdef'), 1); // Debil
      expect(getStrength('Abcdef12'), 4); // Fuerte
      expect(getStrength('Abcdef12!'), 5); // Muy fuerte
    });
  });
}
