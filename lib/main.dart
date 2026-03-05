import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model/currency.dart';

void main() {
  runApp(MaterialApp(
    home: CryptoListWidget(),
  ));
}

class CryptoListWidget extends StatefulWidget {
  @override
  _CryptoListWidgetState createState() => _CryptoListWidgetState();
}

const String _coinGeckoApiUrl =
    'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1';
// TODO: Add your API key here if required by the API provider.

class _CryptoListWidgetState extends State<CryptoListWidget> {
  List<Currency> _currencies = [];
  bool _isLoading = true;
  String? _error;
  final List<MaterialColor> _colors = [Colors.blue, Colors.indigo, Colors.red];

  @override
  void initState() {
    super.initState();
    _getCurrencies();
  }

  Future<void> _getCurrencies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(_coinGeckoApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _currencies = data.map((json) => Currency.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load currencies';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load currencies: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      backgroundColor: Colors.blue,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8.0, 56.0, 8.0, 8.0),
      child: Column(
        children: <Widget>[
          _getAppTitleWidget(),
          _getListViewWidget(),
        ],
      ),
    );
  }

  Widget _getAppTitleWidget() {
    return Text(
      'Crypto Flutter',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
      ),
    );
  }

  Widget _getListViewWidget() {
    return Flexible(
      child: ListView.builder(
        itemCount: _currencies.length,
        itemBuilder: (context, index) {
          final Currency currency = _currencies[index];
          final MaterialColor color = _colors[index % _colors.length];
          return _getListItemWidget(currency, color);
        },
      ),
    );
  }

  Container _getListItemWidget(Currency currency, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(top: 5.0),
      child: Card(
        child: _getListTile(currency, color),
      ),
    );
  }

  ListTile _getListTile(Currency currency, MaterialColor color) {
    return ListTile(
      leading: _getLeadingWidget(currency.name, color),
      title: _getTitleWidget(currency.name),
      subtitle: _getSubtitleWidget(
        currency.currentPrice.toString(),
        currency.priceChangePercentage1h.toStringAsFixed(2),
      ),
      isThreeLine: true,
    );
  }

  CircleAvatar _getLeadingWidget(String currencyName, MaterialColor color) {
    return CircleAvatar(
      backgroundColor: color,
      child: Text(currencyName[0]),
    );
  }

  Text _getTitleWidget(String currencyName) {
    return Text(
      currencyName,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Text _getSubtitleWidget(String priceUsd, String percentChange1h) {
    return Text('\$priceUsd\n1 hour: $percentChange1h%');
  }
}