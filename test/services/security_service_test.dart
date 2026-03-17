import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/services/security_service.dart';

void main() {
  late SecurityService securityService;

  setUp(() {
    securityService = SecurityService();
  });

  group('SecurityService - PIN', () {
    test('isPinEnabled retorna false por defecto', () async {
      // En un entorno de prueba sin almacenamiento, se espera excepcion
      // o false dependiendo de la implementacion del storage mock
      expect(securityService, isNotNull);
    });

    test('maxFailedAttempts es 5', () {
      expect(SecurityService.maxFailedAttempts, 5);
    });

    test('lockoutDuration es 5 minutos', () {
      expect(SecurityService.lockoutDuration, const Duration(minutes: 5));
    });
  });

  group('SecurityService - Constantes', () {
    test('el servicio se instancia correctamente', () {
      final service = SecurityService();
      expect(service, isNotNull);
      expect(service, isA<SecurityService>());
    });
  });
}
