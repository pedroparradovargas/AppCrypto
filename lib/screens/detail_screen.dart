import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/currency.dart';
import '../providers/crypto_provider.dart';

class DetailScreen extends StatefulWidget {
  final Currency currency;

  const DetailScreen({Key? key, required this.currency}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _selectedDays = 7;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.network(
              widget.currency.image,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  widget.currency.symbol.toUpperCase()[0],
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.currency.name,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceSection(),
              const SizedBox(height: 24),
              _buildChartSection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildWalletSection(),
              const SizedBox(height: 24),
              _buildTradeSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    final priceChangeColor = widget.currency.priceChangePercentage24h >= 0
        ? Colors.greenAccent
        : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$${_formatPrice(widget.currency.currentPrice)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Icon(
              widget.currency.priceChangePercentage24h >= 0
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: priceChangeColor,
              size: 20,
            ),
            Text(
              '${widget.currency.priceChangePercentage24h.toStringAsFixed(2)}%',
              style: TextStyle(color: priceChangeColor, fontSize: 18),
            ),
            Text(
              ' (24h)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price Chart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimeSelector(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: provider.isLoadingHistorical
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    )
                  : _buildChart(provider.historicalPrices),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      children: [
        _buildTimeButton('1D', 1),
        _buildTimeButton('1W', 7),
        _buildTimeButton('1M', 30),
        _buildTimeButton('3M', 90),
      ],
    );
  }

  Widget _buildTimeButton(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDays = days;
        });
        context.read<CryptoProvider>().loadHistoricalPrices(
          widget.currency.id,
          days: days,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<double> prices) {
    if (prices.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final isPositive = prices.last >= prices.first;
    final lineColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: prices.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Market Cap', '\$${_formatLargeNumber(widget.currency.marketCap)}'),
          _buildStatRow('24h Volume', '\$${_formatLargeNumber(widget.currency.totalVolume)}'),
          _buildStatRow('24h High', '\$${_formatPrice(widget.currency.high24h)}'),
          _buildStatRow('24h Low', '\${_formatPrice(widget.currency.low24h)}'),
          _buildStatRow('Market Rank', '#${widget.currency.marketCapRank}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, _) {
        final walletItem = provider.getWalletItem(widget.currency.id);
        
        if (walletItem == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'You don\'t have any ${widget.currency.symbol.toUpperCase()}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final profitLoss = provider.calculateProfitLoss(
          walletItem,
          widget.currency.currentPrice,
        );
        final profitLossPercent = provider.calculateProfitLossPercentage(
          walletItem,
          widget.currency.currentPrice,
        );
        final profitLossColor = profitLoss >= 0 ? Colors.greenAccent : Colors.redAccent; // ignore: unused_local_variable

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Holdings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                'Amount',
                '${walletItem.amount.toStringAsFixed(8)} ${walletItem.symbol.toUpperCase()}',
              ),
              _buildStatRow(
                'Value',
                '\$${(walletItem.amount * widget.currency.currentPrice).toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Avg. Buy Price',
                '\$${walletItem.averageBuyPrice.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Profit/Loss',
                '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.toStringAsFixed(2)} (${profitLossPercent.toStringAsFixed(2)}%)',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixText: widget.currency.symbol.toUpperCase(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _buy(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Buy',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _sell(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sell',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _buy() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount');
      return;
    }

    final provider = context.read<CryptoProvider>();
    final success = await provider.buyCurrency(widget.currency, amount);

    if (success) {
      _showMessage('Purchase successful!');
      _amountController.clear();
    } else {
      _showMessage('Insufficient USD balance');
    }
  }

  Future<void> _sell() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount');
      return;
    }

    final provider = context.read<CryptoProvider>();
    final success = await provider.sellCurrency(widget.currency, amount);

    if (success) {
      _showMessage('Sale successful!');
      _amountController.clear();
    } else {
      _showMessage('Insufficient crypto balance');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF16213E),
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

  String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }
}
