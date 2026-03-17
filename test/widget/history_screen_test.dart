import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crypto_flutter/providers/crypto_provider.dart';
import 'package:crypto_flutter/screens/history_screen.dart';

void main() {
  group('HistoryScreen - Widget Tests', () {
    Widget createTestWidget() {
      return ChangeNotifierProvider(
        create: (_) => CryptoProvider(),
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      );
    }

    testWidgets('muestra el titulo Transaction History', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Transaction History'), findsOneWidget);
    });

    testWidgets('muestra mensaje vacio cuando no hay transacciones',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
          find.text('Your trading history will appear here'), findsOneWidget);
    });

    testWidgets('muestra icono de historial vacio', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });
  });
}
