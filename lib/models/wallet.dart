class WalletItem {
  final String currencyId;
  final String name;
  final String symbol;
  final String image;
  final double amount;
  final double averageBuyPrice;

  WalletItem({
    required this.currencyId,
    required this.name,
    required this.symbol,
    required this.image,
    required this.amount,
    required this.averageBuyPrice,
  });

  double get totalValue => amount * averageBuyPrice;

  Map<String, dynamic> toJson() {
    return {
      'currencyId': currencyId,
      'name': name,
      'symbol': symbol,
      'image': image,
      'amount': amount,
      'averageBuyPrice': averageBuyPrice,
    };
  }

  factory WalletItem.fromJson(Map<String, dynamic> json) {
    return WalletItem(
      currencyId: json['currencyId'],
      name: json['name'],
      symbol: json['symbol'],
      image: json['image'],
      amount: (json['amount'] as num).toDouble(),
      averageBuyPrice: (json['averageBuyPrice'] as num).toDouble(),
    );
  }

  WalletItem copyWith({
    String? currencyId,
    String? name,
    String? symbol,
    String? image,
    double? amount,
    double? averageBuyPrice,
  }) {
    return WalletItem(
      currencyId: currencyId ?? this.currencyId,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      image: image ?? this.image,
      amount: amount ?? this.amount,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
    );
  }
}

class Wallet {
  final List<WalletItem> items;
  final double usdBalance;

  Wallet({
    this.items = const [],
    this.usdBalance = 10000.0, // Starting with $10,000 USD simulation
  });

  double get totalValueInUsd {
    double cryptoValue = 0;
    for (var item in items) {
      cryptoValue += item.amount * item.averageBuyPrice;
    }
    return cryptoValue + usdBalance;
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'usdBalance': usdBalance,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      items: (json['items'] as List?)
              ?.map((item) => WalletItem.fromJson(item))
              .toList() ??
          [],
      usdBalance: (json['usdBalance'] as num?)?.toDouble() ?? 10000.0,
    );
  }

  Wallet copyWith({
    List<WalletItem>? items,
    double? usdBalance,
  }) {
    return Wallet(
      items: items ?? this.items,
      usdBalance: usdBalance ?? this.usdBalance,
    );
  }
}
