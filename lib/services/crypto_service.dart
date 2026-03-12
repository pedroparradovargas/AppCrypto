import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency.dart';

class CryptoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  
  // Fetch top cryptocurrencies by market cap
  Future<List<Currency>> getTopCurrencies({
    int page = 1,
    int perPage = 50,
    String vsCurrency = 'usd',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/coins/markets?'
      'vs_currency=$vsCurrency&'
      'order=market_cap_desc&'
      'per_page=$perPage&'
      'page=$page&'
      'sparkline=true&'
      'price_change_percentage=1h,24h,7d',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Currency.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load currencies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load currencies: $e');
    }
  }

  // Fetch detailed info for a specific currency
  Future<Currency?> getCurrencyDetail(String currencyId) async {
    final url = Uri.parse(
      '$_baseUrl/coins/markets?'
      'vs_currency=usd&'
      'ids=$currencyId&'
      'sparkline=true&'
      'price_change_percentage=1h,24h,7d',
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Currency.fromJson(data.first);
        }
        return null;
      } else {
        throw Exception('Failed to load currency detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load currency detail: $e');
    }
  }

  // Fetch historical data for charts
  Future<List<double>> getHistoricalPrices(
    String currencyId, {
    int days = 7,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/coins/$currencyId/market_chart?'
      'vs_currency=usd&'
      'days=$days',
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prices = data['prices'] as List;
        return prices.map((p) => (p[1] as num).toDouble()).toList();
      } else {
        throw Exception('Failed to load historical data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load historical data: $e');
    }
  }

  // Fetch OHLC data for candlestick charts (Binance style)
  Future<List<List<dynamic>>> getOHLCData(
    String currencyId, {
    int days = 7,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/coins/$currencyId/ohlc?'
      'vs_currency=usd&'
      'days=$days',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<List<dynamic>>();
      } else {
        throw Exception('Failed to load OHLC data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load OHLC data: $e');
    }
  }

  // Fetch volume data from market_chart endpoint
  Future<List<List<dynamic>>> getVolumeData(
    String currencyId, {
    int days = 7,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/coins/$currencyId/market_chart?'
      'vs_currency=usd&'
      'days=$days',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final volumes = data['total_volumes'] as List;
        return volumes.cast<List<dynamic>>();
      } else {
        throw Exception('Failed to load volume data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load volume data: $e');
    }
  }

  // Search for currencies
  Future<List<Currency>> searchCurrencies(String query) async {
    final allCurrencies = await getTopCurrencies(perPage: 100);
    final queryLower = query.toLowerCase();
    return allCurrencies.where((c) =>
      c.name.toLowerCase().contains(queryLower) ||
      c.symbol.toLowerCase().contains(queryLower)
    ).toList();
  }
}
