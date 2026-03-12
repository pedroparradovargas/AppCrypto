import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../providers/blockchain_provider.dart';
import '../models/wallet.dart';
import '../models/blockchain_wallet.dart';
import '../utils/responsive.dart';
import 'create_wallet_screen.dart';
import 'payment_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTradingWallet(),
                  _buildBlockchainWallets(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.sp(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: Responsive.w(8),
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.payment, size: Responsive.sp(18)),
                    label: Text(
                      Responsive.isSmall ? '\$' : 'Add Funds',
                      style: TextStyle(fontSize: Responsive.sp(12)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(12),
                        vertical: Responsive.h(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateWalletScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add, size: Responsive.sp(18)),
                    label: Text(
                      Responsive.isSmall ? '+' : 'Wallet',
                      style: TextStyle(fontSize: Responsive.sp(12)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(12),
                        vertical: Responsive.h(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'Manage your trading and blockchain wallets',
            style: TextStyle(
              color: Colors.grey,
              fontSize: Responsive.sp(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Trading'),
          Tab(text: 'Blockchain'),
        ],
      ),
    );
  }

  Widget _buildTradingWallet() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, _) {
        final wallet = provider.wallet;

        return Column(
          children: [
            _buildTradingHeader(wallet, provider),
            Expanded(child: _buildTradingList(provider)),
          ],
        );
      },
    );
  }

  Widget _buildTradingHeader(Wallet wallet, CryptoProvider provider) {
    return Container(
      margin: EdgeInsets.all(Responsive.w(16)),
      padding: EdgeInsets.all(Responsive.w(20)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trading Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: Responsive.sp(14),
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
          SizedBox(height: Responsive.h(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$${wallet.totalValueInUsd.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.sp(32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: Responsive.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                'Crypto',
                wallet.items
                    .fold<double>(
                      0,
                      (sum, item) => sum + (item.amount * item.averageBuyPrice),
                    )
                    .toStringAsFixed(2),
              ),
              _buildBalanceItem(
                'USD',
                wallet.usdBalance.toStringAsFixed(2),
              ),
            ],
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
            fontSize: Responsive.sp(12),
          ),
        ),
        Text(
          '\$$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.sp(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTradingList(CryptoProvider provider) {
    final wallet = provider.wallet;

    if (wallet.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: Responsive.sp(64),
              color: Colors.grey,
            ),
            SizedBox(height: Responsive.h(16)),
            Text(
              'Your trading wallet is empty',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(18)),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Go to Market to buy some crypto!',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(Responsive.w(16)),
      itemCount: wallet.items.length,
      itemBuilder: (context, index) {
        return _buildTradingItem(wallet.items[index], provider);
      },
    );
  }

  Widget _buildTradingItem(WalletItem item, CryptoProvider provider) {
    final currencies = provider.currencies;
    double currentPrice = 0;

    try {
      final currency = currencies.firstWhere((c) => c.id == item.currencyId);
      currentPrice = currency.currentPrice;
    } catch (e) {
      currentPrice = item.averageBuyPrice;
    }

    final profitLoss = provider.calculateProfitLoss(item, currentPrice);
    final profitLossPercent =
        provider.calculateProfitLossPercentage(item, currentPrice);
    final profitLossColor =
        profitLoss >= 0 ? Colors.greenAccent : Colors.redAccent;
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
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(iconSize / 2),
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
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.amount.toStringAsFixed(8)} ${item.symbol.toUpperCase()}',
                  style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(item.amount * currentPrice).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.sp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                style: TextStyle(color: profitLossColor, fontSize: Responsive.sp(12)),
              ),
              Text(
                '(${profitLossPercent.toStringAsFixed(2)}%)',
                style: TextStyle(color: profitLossColor, fontSize: Responsive.sp(12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainWallets() {
    return Consumer<BlockchainProvider>(
      builder: (context, provider, _) {
        if (provider.wallets.isEmpty) {
          return _buildEmptyBlockchainState(provider);
        }

        return Column(
          children: [
            _buildBlockchainHeader(provider),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(Responsive.w(16)),
                itemCount: provider.wallets.length,
                itemBuilder: (context, index) {
                  return _buildBlockchainItem(
                      provider.wallets[index], provider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyBlockchainState(BlockchainProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: Responsive.sp(64),
            color: Colors.grey,
          ),
          SizedBox(height: Responsive.h(16)),
          Text(
            'No blockchain wallets',
            style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(18)),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'Create a wallet to send & receive crypto',
            style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(24)),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWalletScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(24),
                vertical: Responsive.h(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainHeader(BlockchainProvider provider) {
    return Container(
      margin: EdgeInsets.all(Responsive.w(16)),
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.blueAccent),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Networks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(14),
                  ),
                ),
                Text(
                  '${provider.wallets.length} wallet(s)',
                  style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWalletScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainItem(
      BlockchainWallet wallet, BlockchainProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(12)),
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.w(8)),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.currency_bitcoin,
                  color: Colors.blueAccent,
                  size: Responsive.sp(24),
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.network.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                    Text(
                      '${wallet.balance.toStringAsFixed(4)} ${_getNetworkSymbol(wallet.network)}',
                      style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: Responsive.sp(20)),
                        SizedBox(width: Responsive.w(8)),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteWallet(wallet, provider);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          Container(
            padding: EdgeInsets.all(Responsive.w(8)),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    wallet.address,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: Responsive.sp(12),
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: Responsive.sp(16), color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: wallet.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNetworkSymbol(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'ETH';
      case 'polygon':
        return 'MATIC';
      case 'binancesmartchain':
        return 'BNB';
      default:
        return network.toUpperCase();
    }
  }

  void _confirmDeleteWallet(
      BlockchainWallet wallet, BlockchainProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text(
          'Are you sure you want to delete this ${wallet.network} wallet? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteWallet(wallet.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
