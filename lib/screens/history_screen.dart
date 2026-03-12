import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/crypto_provider.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildTransactionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Transaction History',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.sp(28),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, _) {
        final transactions = provider.transactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: Responsive.sp(64),
                  color: Colors.grey,
                ),
                SizedBox(height: Responsive.h(16)),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: Responsive.sp(18),
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                Text(
                  'Your trading history will appear here',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: Responsive.sp(14),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(Responsive.w(16)),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionItem(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isBuy = transaction.type == TransactionType.buy;
    final typeColor = isBuy ? Colors.greenAccent : Colors.redAccent;
    final typeIcon = isBuy ? Icons.arrow_downward : Icons.arrow_upward;
    final typeText = isBuy ? 'Buy' : 'Sell';
    final iconSize = Responsive.w(48).clamp(36.0, 64.0);

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(12)),
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(iconSize / 2),
            ),
            child: Icon(typeIcon, color: typeColor, size: Responsive.sp(24)),
          ),
          SizedBox(width: Responsive.w(12)),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      typeText,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: Responsive.sp(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    Text(
                      transaction.currencySymbol.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.sp(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  '${transaction.amount.toStringAsFixed(8)} @ \$${transaction.pricePerUnit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: Responsive.sp(12),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(transaction.timestamp),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: Responsive.sp(12),
                  ),
                ),
              ],
            ),
          ),
          // Total Value
          Text(
            '${isBuy ? '-' : '+'}\$${transaction.totalValue.toStringAsFixed(2)}',
            style: TextStyle(
              color: typeColor,
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
