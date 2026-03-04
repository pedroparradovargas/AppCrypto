import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var currencies = await getCurrencies();

  print(currencies);

  runApp(new MaterialApp(
    home: new CryptoListWidget(currencies)
  ));
}

Future<List> getCurrencies() async {
  String url = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1';
  http.Response response = await http.get(Uri.parse(url));
  return jsonDecode(response.body);
}

class CryptoListWidget extends StatelessWidget {

  final List<MaterialColor> _colors = [Colors.blue, Colors.indigo, Colors.red];
  final List _currencies;

  CryptoListWidget(this._currencies);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: _buildBody(),
      backgroundColor: Colors.blue
    );
  }

  Widget _buildBody() {
    return new Container(
      margin: const EdgeInsets.fromLTRB(8.0, 56.0, 8.0, 8.0),
      child: new Column(
        children: <Widget>[
          _getAppTitleWidget(),
          _getListViewWidget()
        ]
      )
    );
  }

  Widget _getAppTitleWidget() {
    return new Text(
      'Crypto Flutter',
      style: new TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24.0
      )
    );
  }

  Widget _getListViewWidget() {
    return new Flexible(
        child: new ListView.builder(
            itemCount: _currencies.length,
            itemBuilder: (context, index) {
              final Map currency = _currencies[index];
              final MaterialColor color = _colors[index % _colors.length];
              return _getListItemWidget(currency, color);
            }
        )
    );
  }

  Container _getListItemWidget(Map currency, MaterialColor color) {
    return new Container(
      margin: const EdgeInsets.only(top: 5.0),
      child: new Card(
        child: _getListTile(currency, color)
      )
    );
  }

  ListTile _getListTile(Map currency, MaterialColor color) {
    return new ListTile(
      leading: _getLeadingWidget(currency['name'], color),
      title: _getTitleWidget(currency['name']),
      subtitle: _getSubtitleWidget(currency['current_price']?.toString() ?? '0', currency['price_change_percentage_1h_in_currency']?.toStringAsFixed(2) ?? '0'),
      isThreeLine: true
    );
  }

  CircleAvatar _getLeadingWidget(String currencyName, MaterialColor color) {
    return new CircleAvatar(
      backgroundColor: color,
      child: new Text(currencyName[0])
    );
  }

  Text _getTitleWidget(String currencyName) {
    return new Text(
      currencyName,
      style: new TextStyle(fontWeight: FontWeight.bold)
    );
  }

  Text _getSubtitleWidget(String priceUsd, String percentChange1h) {
    return new Text('\$$priceUsd\n1 hour: $percentChange1h%');
  }

}