import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import '../utils/responsive.dart';

/// Widget de grafica candlestick estilo Binance
class CandlestickChartWidget extends StatelessWidget {
  final List<Candle> candles;
  final bool isLoading;
  final int selectedDays;
  final ValueChanged<int> onIntervalChanged;

  const CandlestickChartWidget({
    Key? key,
    required this.candles,
    required this.isLoading,
    required this.selectedDays,
    required this.onIntervalChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con selector de intervalo
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Responsive.w(8),
          runSpacing: Responsive.h(8),
          children: [
            Text(
              'Candlestick Chart',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildIntervalSelector(),
          ],
        ),
        SizedBox(height: Responsive.h(12)),
        // Chart
        Container(
          height: Responsive.h(300).clamp(250.0, 450.0),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                )
              : candles.isEmpty
                  ? Center(
                      child: Text(
                        'No hay datos disponibles',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: Responsive.sp(14),
                        ),
                      ),
                    )
                  : Candlesticks(
                      candles: candles,
                    ),
        ),
        SizedBox(height: Responsive.h(8)),
        // Leyenda
        _buildLegend(),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    return Row(
      children: [
        _buildIntervalButton('1D', 1),
        _buildIntervalButton('1W', 7),
        _buildIntervalButton('1M', 30),
        _buildIntervalButton('3M', 90),
        _buildIntervalButton('1Y', 365),
      ],
    );
  }

  Widget _buildIntervalButton(String label, int days) {
    final isSelected = selectedDays == days;
    return GestureDetector(
      onTap: () => onIntervalChanged(days),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(10),
          vertical: Responsive.h(6),
        ),
        margin: EdgeInsets.only(left: Responsive.w(4)),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: Responsive.sp(12),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    if (candles.isEmpty) return const SizedBox.shrink();

    final latest = candles.first;
    final change = latest.close - latest.open;
    final changePercent = latest.open != 0
        ? (change / latest.open) * 100
        : 0.0;
    final isPositive = change >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Row(
      children: [
        _buildLegendItem('O', latest.open.toStringAsFixed(2), Colors.grey),
        SizedBox(width: Responsive.w(12)),
        _buildLegendItem('H', latest.high.toStringAsFixed(2), Colors.greenAccent),
        SizedBox(width: Responsive.w(12)),
        _buildLegendItem('L', latest.low.toStringAsFixed(2), Colors.redAccent),
        SizedBox(width: Responsive.w(12)),
        _buildLegendItem('C', latest.close.toStringAsFixed(2), color),
        const Spacer(),
        Text(
          '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
          style: TextStyle(
            color: color,
            fontSize: Responsive.sp(12),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            color: Colors.grey,
            fontSize: Responsive.sp(11),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: Responsive.sp(11),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
