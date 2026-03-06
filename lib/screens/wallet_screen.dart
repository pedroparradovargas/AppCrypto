import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../models/wallet.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Consumer<CryptoProvider>(
          builder: (context, provider, _) {
            final wallet = provider.wallet;

            return Column(
              children: [
                _buildHeader(wallet, provider),
                Expanded(child: _buildWalletList(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Wallet wallet, CryptoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Wallet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${wallet.totalValueInUsd.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBalanceItem(
                      'Crypto',
                      wallet.items.fold<double>(
                        0,
                        (sum, item) => sum + (item.amount * item.averageBuyPrice),
                      ).toStringAsFixed(2),
                    ),
                    _buildBalanceItem(
                      'USD',
                      wallet.usdBalance.toStringAsFixed(2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          '\$$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletList(CryptoProvider provider) {
    final wallet = provider.wallet;

    if (wallet.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Your wallet is empty',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Market to buy some crypto!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wallet.items.length,
      itemBuilder: (context, index) {
        return _buildWalletItem(wallet.items[index], provider);
      },
    );
  }

  Widget _buildWalletItem(WalletItem item, CryptoProvider provider) {
    final currencies = provider.currencies;
    double currentPrice = 0;
    
    try {
      final currency = currencies.firstWhere((c) => c.id == item.currencyId);
      currentPrice = currency.currentPrice;
    } catch (e) {
      currentPrice = item.averageBuyPrice;
    }

    final profitLoss = provider.calculateProfitLoss(item, currentPrice);
    final profitLossPercent = provider.calculateProfitLossPercentage(item, currentPrice);
    final profitLossColor = profitLoss >= 0 ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.network(
              item.image,
              errorBuilder: (_, __, ___) => CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  item.symbol.toUpperCase()[0],
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.amount.toStringAsFixed(8)} ${item.symbol.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Value and P/L
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(item.amount * currentPrice).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                style: TextStyle(
                  color: profitLossColor,
                  fontSize: 12,
                ),
              ),
              Text(
                '(${profitLossPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: profitLossColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
