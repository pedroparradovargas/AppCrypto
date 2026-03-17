import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing app security: PIN, biometric auth, and 2FA
class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const _pinHashKey = 'security_pin_hash';
  static const _pinEnabledKey = 'security_pin_enabled';
  static const _biometricEnabledKey = 'security_biometric_enabled';
  static const _twoFactorEnabledKey = 'security_2fa_enabled';
  static const _twoFactorSecretKey = 'security_2fa_secret';
  static const _failedAttemptsKey = 'security_failed_attempts';
  static const _lockoutUntilKey = 'security_lockout_until';

  // Lockout configuration
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if PIN is configured
  Future<bool> isPinEnabled() async {
    final enabled = await _storage.read(key: _pinEnabledKey);
    return enabled == 'true';
  }

  /// Set up a new PIN
  Future<void> setPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hashedPin);
    await _storage.write(key: _pinEnabledKey, value: 'true');
    await _resetFailedAttempts();
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    // Check lockout
    if (await isLockedOut()) {
      return false;
    }

    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = storedHash == inputHash;

    if (isValid) {
      await _resetFailedAttempts();
    } else {
      await _incrementFailedAttempts();
    }

    return isValid;
  }

  /// Change PIN (requires old PIN verification)
  Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;

    await setPin(newPin);
    return true;
  }

  /// Remove PIN
  Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
    await _resetFailedAttempts();
  }

  /// Check if biometric auth is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enable/disable biometric auth
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Check if 2FA is enabled
  Future<bool> is2FAEnabled() async {
    final enabled = await _storage.read(key: _twoFactorEnabledKey);
    return enabled == 'true';
  }

  /// Enable 2FA and generate secret
  Future<String> enable2FA() async {
    // Generate a random base32 secret for TOTP
    final secret = _generateTOTPSecret();
    await _storage.write(key: _twoFactorSecretKey, value: secret);
    await _storage.write(key: _twoFactorEnabledKey, value: 'true');
    return secret;
  }

  /// Disable 2FA
  Future<void> disable2FA() async {
    await _storage.delete(key: _twoFactorSecretKey);
    await _storage.write(key: _twoFactorEnabledKey, value: 'false');
  }

  /// Verify TOTP code (simplified demo)
  Future<bool> verify2FACode(String code) async {
    // In production, use a proper TOTP library (e.g., otp package)
    // This demo accepts any 6-digit code
    if (code.length != 6) return false;
    final isNumeric = int.tryParse(code) != null;
    return isNumeric;
  }

  /// Get 2FA secret
  Future<String?> get2FASecret() async {
    return await _storage.read(key: _twoFactorSecretKey);
  }

  /// Generate TOTP secret (base32 encoded)
  String _generateTOTPSecret() {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(timestamp));
    final bytes = hash.bytes;

    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(base32Chars[bytes[i % bytes.length] % base32Chars.length]);
    }
    return buffer.toString();
  }

  /// Check if account is locked out
  Future<bool> isLockedOut() async {
    final lockoutUntil = await _storage.read(key: _lockoutUntilKey);
    if (lockoutUntil == null) return false;

    final lockoutTime = DateTime.tryParse(lockoutUntil);
    if (lockoutTime == null) return false;

    if (DateTime.now().isBefore(lockoutTime)) {
      return true;
    }

    // Lockout expired
    await _resetFailedAttempts();
    return false;
  }

  /// Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime() async {
    final lockoutUntil = await _storage.read(key: _lockoutUntilKey);
    if (lockoutUntil == null) return null;

    final lockoutTime = DateTime.tryParse(lockoutUntil);
    if (lockoutTime == null) return null;

    final remaining = lockoutTime.difference(DateTime.now());
    if (remaining.isNegative) return null;

    return remaining;
  }

  /// Get number of failed attempts
  Future<int> getFailedAttempts() async {
    final attempts = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(attempts ?? '0') ?? 0;
  }

  /// Increment failed attempts and lock if needed
  Future<void> _incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    final newCount = current + 1;
    await _storage.write(key: _failedAttemptsKey, value: newCount.toString());

    if (newCount >= maxFailedAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await _storage.write(
        key: _lockoutUntilKey,
        value: lockoutUntil.toIso8601String(),
      );
    }
  }

  /// Reset failed attempts
  Future<void> _resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  /// Clear all security settings
  Future<void> clearAll() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinEnabledKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _twoFactorEnabledKey);
    await _storage.delete(key: _twoFactorSecretKey);
    await _resetFailedAttempts();
  }
}
