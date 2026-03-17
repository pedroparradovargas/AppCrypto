import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_profile.dart';
import '../services/security_service.dart';
import '../services/firebase_auth_service.dart';
import '../main.dart' show firebaseInitialized;

/// Provider para manejar autenticacion Firebase + seguridad local
class AuthProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  late final FirebaseAuthService? _firebaseAuthService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Firebase auth state
  User? _firebaseUser;
  UserProfile? _userProfile;
  bool _isFirebaseAuthenticated = false;
  StreamSubscription<User?>? _authSubscription;

  // Local security state
  bool _isAuthenticated = false;
  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  bool _is2FAEnabled = false;
  bool _isLockedOut = false;
  int _failedAttempts = 0;
  Duration? _remainingLockout;
  bool _isLoading = true;
  String? _error;

  // Getters - Firebase
  User? get firebaseUser => _firebaseUser;
  UserProfile? get userProfile => _userProfile;
  bool get isFirebaseAuthenticated => _isFirebaseAuthenticated;

  // Getters - Local security
  bool get isAuthenticated => _isAuthenticated;
  bool get isPinEnabled => _isPinEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get is2FAEnabled => _is2FAEnabled;
  bool get isLockedOut => _isLockedOut;
  int get failedAttempts => _failedAttempts;
  Duration? get remainingLockout => _remainingLockout;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get requiresAuth => _isPinEnabled;

  /// Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Solo inicializar Firebase si esta configurado
    if (firebaseInitialized) {
      _firebaseAuthService = FirebaseAuthService();

      // Escuchar cambios de autenticacion Firebase
      _authSubscription = _firebaseAuthService!.authStateChanges.listen((user) async {
        _firebaseUser = user;
        _isFirebaseAuthenticated = user != null;

        if (user != null) {
          _userProfile = await _firebaseAuthService!.getUserProfile(user.uid);
        } else {
          _userProfile = null;
        }

        notifyListeners();
      });
    } else {
      _firebaseAuthService = null;
      debugPrint('Firebase no disponible - modo sin Firebase');
      // Sin Firebase, saltar autenticacion Firebase y ir directo a la app
      _isFirebaseAuthenticated = true;
    }

    // Cargar estado de seguridad local
    _isPinEnabled = await _securityService.isPinEnabled();
    _isBiometricEnabled = await _securityService.isBiometricEnabled();
    _is2FAEnabled = await _securityService.is2FAEnabled();
    _isLockedOut = await _securityService.isLockedOut();
    _failedAttempts = await _securityService.getFailedAttempts();
    _remainingLockout = await _securityService.getRemainingLockoutTime();

    // Si no hay PIN, el usuario esta autenticado localmente
    if (!_isPinEnabled) {
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ==================== FIREBASE AUTH ====================

  /// Registrar con email y password
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_firebaseAuthService == null) {
      _error = 'Firebase no esta configurado';
      notifyListeners();
      return false;
    }

    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _firebaseAuthService!.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _firebaseUser = _firebaseAuthService!.currentUser;
      _isFirebaseAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al registrar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesion con email y password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuthService == null) {
      _error = 'Firebase no esta configurado';
      notifyListeners();
      return false;
    }

    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _firebaseAuthService!.signInWithEmail(
        email: email,
        password: password,
      );
      _firebaseUser = _firebaseAuthService!.currentUser;
      _isFirebaseAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al iniciar sesion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Enviar email de recuperacion de contraseña
  Future<bool> sendPasswordReset(String email) async {
    if (_firebaseAuthService == null) {
      _error = 'Firebase no esta configurado';
      notifyListeners();
      return false;
    }

    _error = null;
    notifyListeners();

    try {
      await _firebaseAuthService!.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al enviar email: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesion (Firebase + local)
  Future<void> signOut() async {
    await _firebaseAuthService?.signOut();
    _firebaseUser = null;
    _userProfile = null;
    _isFirebaseAuthenticated = false;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Registrar huella digital durante el registro
  Future<bool> registerBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        _error = 'Biometria no disponible en este dispositivo';
        notifyListeners();
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Registra tu huella digital para acceso rapido',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _securityService.setBiometricEnabled(true);
        _isBiometricEnabled = true;

        // Actualizar en Firestore
        if (_firebaseUser != null && _firebaseAuthService != null) {
          await _firebaseAuthService!.updateBiometricRegistration(
            _firebaseUser!.uid,
            true,
          );
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = 'Error al registrar biometria: $e';
      notifyListeners();
      return false;
    }
  }

  /// Autenticar con biometria
  Future<bool> authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella digital para acceder',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isAuthenticated = true;
        notifyListeners();
      }

      return authenticated;
    } catch (e) {
      _error = 'Error de autenticacion biometrica';
      notifyListeners();
      return false;
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este email ya esta registrado';
      case 'invalid-email':
        return 'Email invalido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta mas tarde';
      case 'invalid-credential':
        return 'Credenciales invalidas';
      default:
        return 'Error de autenticacion: $code';
    }
  }

  // ==================== LOCAL SECURITY (PIN/2FA) ====================

  /// Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    _error = null;

    _isLockedOut = await _securityService.isLockedOut();
    if (_isLockedOut) {
      _remainingLockout = await _securityService.getRemainingLockoutTime();
      final minutes = _remainingLockout?.inMinutes ?? 5;
      _error = 'Cuenta bloqueada. Intenta en $minutes minutos';
      notifyListeners();
      return false;
    }

    final isValid = await _securityService.verifyPin(pin);

    if (isValid) {
      _isAuthenticated = true;
      _failedAttempts = 0;
      _error = null;
    } else {
      _failedAttempts = await _securityService.getFailedAttempts();
      final remaining = SecurityService.maxFailedAttempts - _failedAttempts;
      if (remaining > 0) {
        _error = 'PIN incorrecto. $remaining intentos restantes';
      } else {
        _isLockedOut = true;
        _remainingLockout = await _securityService.getRemainingLockoutTime();
        _error = 'Cuenta bloqueada por demasiados intentos';
      }
    }

    notifyListeners();
    return isValid;
  }

  /// Set up PIN
  Future<void> setupPin(String pin) async {
    await _securityService.setPin(pin);
    _isPinEnabled = true;
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    final success = await _securityService.changePin(oldPin, newPin);
    if (!success) {
      _error = 'PIN actual incorrecto';
      notifyListeners();
    }
    return success;
  }

  /// Remove PIN
  Future<void> removePin(String currentPin) async {
    final isValid = await _securityService.verifyPin(currentPin);
    if (isValid) {
      await _securityService.removePin();
      _isPinEnabled = false;
      _isAuthenticated = true;
      _error = null;
    } else {
      _error = 'PIN incorrecto';
    }
    notifyListeners();
  }

  /// Toggle biometric auth
  Future<void> toggleBiometric(bool enabled) async {
    await _securityService.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  /// Enable 2FA
  Future<String?> enable2FA() async {
    try {
      final secret = await _securityService.enable2FA();
      _is2FAEnabled = true;
      notifyListeners();
      return secret;
    } catch (e) {
      _error = 'Error al activar 2FA';
      notifyListeners();
      return null;
    }
  }

  /// Disable 2FA
  Future<void> disable2FA() async {
    await _securityService.disable2FA();
    _is2FAEnabled = false;
    notifyListeners();
  }

  /// Verify 2FA code
  Future<bool> verify2FA(String code) async {
    return await _securityService.verify2FACode(code);
  }

  /// Get 2FA secret for QR display
  Future<String?> get2FASecret() async {
    return await _securityService.get2FASecret();
  }

  /// Lock the app (require re-authentication)
  void lock() {
    if (_isPinEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
