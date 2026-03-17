import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crypto_flutter/providers/crypto_provider.dart';
import 'package:crypto_flutter/screens/home_screen.dart';

void main() {
  group('HomeScreen - Widget Tests', () {
    Widget createTestWidget() {
      return ChangeNotifierProvider(
        create: (_) => CryptoProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('muestra el titulo del mercado', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Market'), findsWidgets);
    });

    testWidgets('muestra campo de busqueda', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('muestra indicador de carga inicialmente', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // El provider inicializa con estado de carga
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('el campo de busqueda acepta texto', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Bitcoin');
      await tester.pump();

      expect(find.text('Bitcoin'), findsWidgets);
    });
  });
}
