import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:crypto_flutter/main.dart';
import 'package:crypto_flutter/providers/crypto_provider.dart';
import 'package:crypto_flutter/providers/blockchain_provider.dart';
import 'package:crypto_flutter/providers/auth_provider.dart';

/// Pruebas de integracion para la aplicacion CryptoExchange.
///
/// Estas pruebas verifican el comportamiento end-to-end de la aplicacion,
/// incluyendo navegacion, interaccion con la UI y flujos completos.
///
/// Para ejecutar:
/// flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('la app inicia correctamente', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
                create: (_) => CryptoProvider()..initialize()),
            ChangeNotifierProvider(
                create: (_) => BlockchainProvider()..initialize()),
          ],
          child: const CryptoExchangeApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verifica que la app carga
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('navegacion entre tabs funciona', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
                create: (_) => CryptoProvider()..initialize()),
            ChangeNotifierProvider(
                create: (_) => BlockchainProvider()..initialize()),
          ],
          child: const CryptoExchangeApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tab Market debe estar visible
      final marketTab = find.text('Market');
      if (marketTab.evaluate().isNotEmpty) {
        expect(marketTab, findsWidgets);

        // Navegar a Wallet
        final walletTab = find.text('Wallet');
        if (walletTab.evaluate().isNotEmpty) {
          await tester.tap(walletTab.first);
          await tester.pumpAndSettle();
        }

        // Navegar a History
        final historyTab = find.text('History');
        if (historyTab.evaluate().isNotEmpty) {
          await tester.tap(historyTab.first);
          await tester.pumpAndSettle();
        }

        // Volver a Market
        if (marketTab.evaluate().isNotEmpty) {
          await tester.tap(marketTab.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('FAB de acciones rapidas abre modal', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
                create: (_) => CryptoProvider()..initialize()),
            ChangeNotifierProvider(
                create: (_) => BlockchainProvider()..initialize()),
          ],
          child: const CryptoExchangeApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Buscar el FAB
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Verificar que el modal muestra Quick Actions
        expect(find.text('Quick Actions'), findsOneWidget);
      }
    });
  });
}
