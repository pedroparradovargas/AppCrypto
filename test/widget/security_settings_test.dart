import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crypto_flutter/providers/auth_provider.dart';
import 'package:crypto_flutter/screens/security_settings_screen.dart';

void main() {
  group('SecuritySettingsScreen - Widget Tests', () {
    Widget createTestWidget() {
      return ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );
    }

    testWidgets('muestra titulo Seguridad', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Seguridad'), findsOneWidget);
    });

    testWidgets('muestra seccion de PIN de acceso', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Acceso con PIN'), findsOneWidget);
      expect(find.text('PIN de Acceso'), findsOneWidget);
    });

    testWidgets('muestra seccion de autenticacion biometrica', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Autenticacion Biometrica'), findsOneWidget);
      expect(find.text('Huella Digital / Face ID'), findsOneWidget);
    });

    testWidgets('muestra seccion 2FA', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Autenticacion de Dos Factores (2FA)'), findsOneWidget);
      expect(find.text('Google Authenticator / TOTP'), findsOneWidget);
    });

    testWidgets('muestra nivel de seguridad basico por defecto',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.textContaining('Basico'), findsOneWidget);
    });

    testWidgets('muestra header de proteccion de cuenta', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Proteccion de Cuenta'), findsOneWidget);
    });

    testWidgets('tiene switches para PIN, biometria y 2FA', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Switch), findsNWidgets(3));
    });

    testWidgets('icono de escudo esta presente', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });
}
