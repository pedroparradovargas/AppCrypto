import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../models/currency.dart';
import '../utils/responsive.dart';
import 'detail_screen.dart';
import 'payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
            _buildSearchBar(),
            Expanded(child: _buildCurrencyList()),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CryptoMarket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.sp(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<CryptoProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      '\$${provider.wallet.usdBalance.toStringAsFixed(2)} USD',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: Responsive.sp(16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<CryptoProvider>().fetchCurrencies();
            },
          ),
          IconButton(
            icon: Icon(Icons.add_circle, color: Colors.greenAccent,
                size: Responsive.sp(32)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search cryptocurrencies...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          context.read<CryptoProvider>().searchCurrencies(value);
        },
      ),
    );
  }

  Widget _buildCurrencyList() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading data',
                  style: TextStyle(color: Colors.white, fontSize: Responsive.sp(18)),
                ),
                SizedBox(height: Responsive.h(8)),
                ElevatedButton(
                  onPressed: () => provider.fetchCurrencies(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final currencies = provider.currencies;

        if (currencies.isEmpty) {
          return Center(
            child: Text(
              'No cryptocurrencies found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(Responsive.w(16)),
          itemCount: currencies.length,
          itemBuilder: (context, index) {
            return _buildCurrencyCard(currencies[index]);
          },
        );
      },
    );
  }

  Widget _buildCurrencyCard(Currency currency) {
    final priceChangeColor = currency.priceChangePercentage24h >= 0
        ? Colors.greenAccent
        : Colors.redAccent;

    final priceChangeIcon = currency.priceChangePercentage24h >= 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    final iconSize = Responsive.w(48).clamp(36.0, 64.0);

    return GestureDetector(
      onTap: () {
        context.read<CryptoProvider>().selectCurrency(currency);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(currency: currency),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.h(12)),
        padding: EdgeInsets.all(Responsive.w(16)),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: Responsive.w(30),
              child: Text(
                '${currency.marketCapRank}',
                style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
              ),
            ),
            // Image
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(iconSize / 2),
                child: Image.network(
                  currency.image,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      currency.symbol.toUpperCase()[0],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            // Name and Symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currency.symbol.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: Responsive.sp(14),
                    ),
                  ),
                ],
              ),
            ),
            // Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_formatPrice(currency.currentPrice)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(priceChangeIcon, color: priceChangeColor,
                        size: Responsive.sp(14)),
                    Text(
                      '${currency.priceChangePercentage24h.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: priceChangeColor,
                        fontSize: Responsive.sp(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(6);
    }
  }
}
