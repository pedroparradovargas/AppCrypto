enum TransactionType { buy, sell }

class Transaction {
  final String id;
  final String currencyId;
  final String currencyName;
  final String currencySymbol;
  final String currencyImage;
  final TransactionType type;
  final double amount;
  final double pricePerUnit;
  final double totalValue;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.currencyId,
    required this.currencyName,
    required this.currencySymbol,
    required this.currencyImage,
    required this.type,
    required this.amount,
    required this.pricePerUnit,
    required this.totalValue,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currencyId': currencyId,
      'currencyName': currencyName,
      'currencySymbol': currencySymbol,
      'currencyImage': currencyImage,
      'type': type.name,
      'amount': amount,
      'pricePerUnit': pricePerUnit,
      'totalValue': totalValue,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      currencyId: json['currencyId'],
      currencyName: json['currencyName'],
      currencySymbol: json['currencySymbol'],
      currencyImage: json['currencyImage'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.buy,
      ),
      amount: (json['amount'] as num).toDouble(),
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
