import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blockchain_provider.dart';
import '../utils/responsive.dart';

/// Screen for depositing funds and managing payment methods
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  String? _selectedPaymentMethodId;

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Funds'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BlockchainProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Deposit section
                _buildDepositSection(provider),
                SizedBox(height: Responsive.h(24)),

                // Add card section
                _buildAddCardSection(provider),
                SizedBox(height: Responsive.h(24)),

                // Saved payment methods
                _buildPaymentMethodsSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDepositSection(BlockchainProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deposit Funds',
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Add funds to your wallet using your debit/credit card.',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            if (provider.paymentMethods.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethodId,
                decoration: InputDecoration(
                  labelText: 'Select Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: provider.paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method.id,
                    child: Text('${method.brand} ****${method.last4}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethodId = value;
                  });
                },
              ),
              SizedBox(height: Responsive.h(16)),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    provider.isLoadingWallets ? null : () => _deposit(provider),
                icon: provider.isLoadingWallets
                    ? SizedBox(
                        width: Responsive.sp(20),
                        height: Responsive.sp(20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  'Deposit Now',
                  style: TextStyle(fontSize: Responsive.sp(14)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.h(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardSection(BlockchainProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Credit/Debit Card',
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.w(12)),
                Expanded(
                  child: TextField(
                    controller: _cvcController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVC',
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(16)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addCard(provider),
                icon: const Icon(Icons.credit_card),
                label: Text(
                  'Add Card',
                  style: TextStyle(fontSize: Responsive.sp(14)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.h(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(BlockchainProvider provider) {
    if (provider.paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Payment Methods',
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            ...provider.paymentMethods.map((method) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.credit_card),
                title: Text('${method.brand} ****${method.last4}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePaymentMethod(provider, method.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _deposit(BlockchainProvider provider) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showSnackBar('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount');
      return;
    }

    String? paymentMethodId = _selectedPaymentMethodId;

    // If no payment method selected and there's a saved one, use the first one
    if (paymentMethodId == null && provider.paymentMethods.isNotEmpty) {
      paymentMethodId = provider.paymentMethods.first.id;
    }

    if (paymentMethodId == null) {
      _showSnackBar('Please add a payment method first');
      return;
    }

    final result = await provider.deposit(
      amount: amount,
      paymentMethodId: paymentMethodId,
    );

    if (result != null && mounted) {
      if (result.success) {
        _showSnackBar('Deposit successful!', isSuccess: true);
        _amountController.clear();
      } else {
        _showSnackBar('Deposit failed: ${result.message}');
      }
    }
  }

  Future<void> _addCard(BlockchainProvider provider) async {
    final cardNumber = _cardNumberController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvc = _cvcController.text.trim();

    if (!_isValidCardNumber(cardNumber)) {
      _showSnackBar('Please enter a valid card number');
      return;
    }

    if (expiry.length < 5) {
      _showSnackBar('Please enter a valid expiry date');
      return;
    }

    if (!_isValidCVC(cvc)) {
      _showSnackBar('Please enter a valid CVC (3-4 digits)');
      return;
    }

    final parts = expiry.split('/');
    if (parts.length != 2) {
      _showSnackBar('Please use format MM/YY');
      return;
    }

    // Validate month is 1-12
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) {
      _showSnackBar('Invalid month. Must be between 01-12');
      return;
    }

    // Check if card is expired
    final now = DateTime.now();
    final currentYear = now.year % 100; // Last 2 digits
    final currentMonth = now.month;
    if (year != null && (year < currentYear || (year == currentYear && month < currentMonth))) {
      _showSnackBar('Card has expired');
      return;
    }

    final paymentMethod = await provider.addPaymentMethod(
      cardNumber: cardNumber,
      expiryMonth: parts[0],
      expiryYear: parts[1],
      cvc: cvc,
    );

    if (paymentMethod != null && mounted) {
      _showSnackBar('Card added successfully!', isSuccess: true);
      _cardNumberController.clear();
      _expiryController.clear();
      _cvcController.clear();
    }
  }

  Future<void> _deletePaymentMethod(
    BlockchainProvider provider,
    String paymentMethodId,
  ) async {
    final result = await provider.deletePaymentMethod(paymentMethodId);
    if (result && mounted) {
      _showSnackBar('Payment method deleted');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
      ),
    );
  }

  /// Validate card number using Luhn algorithm
  bool _isValidCardNumber(String number) {
    if (number.length < 13 || number.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      final char = number[i];
      final digit = int.tryParse(char);
      if (digit == null) return false; // Non-numeric character

      if (alternate) {
        int doubled = digit * 2;
        if (doubled > 9) {
          doubled = (doubled ~/ 10) + (doubled % 10);
        }
        sum += doubled;
      } else {
        sum += digit;
      }
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validate CVC (3-4 digits)
  bool _isValidCVC(String cvc) {
    if (cvc.length < 3 || cvc.length > 4) return false;
    return int.tryParse(cvc) != null;
  }
}
