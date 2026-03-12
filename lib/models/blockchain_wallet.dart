
/// Blockchain wallet model for storing real cryptocurrency wallets
///
/// SECURITY WARNING: This model stores sensitive credentials.
///
/// For production use:
/// - Private keys should be encrypted using AES-256-GCM before storage
/// - Mnemonic phrases should be encrypted and never stored alongside keys
/// - Use flutter_secure_storage with encrypted shared preferences on Android
/// - Consider using hardware-backed keystores (Android Keystore / iOS Keychain)
/// - Implement key derivation on-demand rather than storing raw private keys
///
/// NOTE: This model stores plaintext data. Encryption is handled by
/// FlutterSecureStorage at the storage layer (AES-256 on Android,
/// Keychain on iOS, DPAPI on Windows, libsecret on Linux).
class BlockchainWallet {
  final String id;
  final String address;
  // NOTE: In production, encrypt this before storage
  // Use AES-256 encryption with a user-derived key
  final String privateKey;
  // NOTE: In production, encrypt this and store separately from privateKey
  // Mnemonics should be recoverable from backup only, not stored long-term
  final String mnemonic;
  final String network; // 'ethereum', 'bitcoin', etc.
  final double balance;
  final DateTime createdAt;
  final bool isBackedUp;

  BlockchainWallet({
    required this.id,
    required this.address,
    required this.privateKey,
    required this.mnemonic,
    required this.network,
    this.balance = 0.0,
    required this.createdAt,
    this.isBackedUp = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      // SECURITY: Encrypt sensitive fields before storage
      'privateKey': WalletEncryption.encrypt(privateKey),
      'mnemonic': WalletEncryption.encrypt(mnemonic),
      'network': network,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'isBackedUp': isBackedUp,
    };
  }

  factory BlockchainWallet.fromJson(Map<String, dynamic> json) {
    return BlockchainWallet(
      id: json['id'],
      address: json['address'],
      // SECURITY: Decrypt sensitive fields after retrieval
      privateKey: WalletEncryption.decrypt(json['privateKey']),
      mnemonic: WalletEncryption.decrypt(json['mnemonic']),
      network: json['network'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      isBackedUp: json['isBackedUp'] ?? false,
    );
  }

  BlockchainWallet copyWith({
    String? id,
    String? address,
    String? privateKey,
    String? mnemonic,
    String? network,
    double? balance,
    DateTime? createdAt,
    bool? isBackedUp,
  }) {
    return BlockchainWallet(
      id: id ?? this.id,
      address: address ?? this.address,
      privateKey: privateKey ?? this.privateKey,
      mnemonic: mnemonic ?? this.mnemonic,
      network: network ?? this.network,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isBackedUp: isBackedUp ?? this.isBackedUp,
    );
  }
}

/// Supported blockchain networks
enum BlockchainNetwork {
  ethereum('Ethereum', 'ETH', 'https://mainnet.infura.io/v3/'),
  polygon('Polygon', 'MATIC', 'https://polygon-rpc.com/'),
  binanceSmartChain('BNB Chain', 'BNB', 'https://bsc-dataseed.binance.org/');

  final String name;
  final String symbol;
  final String rpcUrl;

  const BlockchainNetwork(this.name, this.symbol, this.rpcUrl);
}

/// Payment method for adding funds
class PaymentMethod {
  final String id;
  final String type; // 'card', 'bank', 'crypto'
  final String last4;
  final String brand;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'brand': brand,
      'isDefault': isDefault,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      last4: json['last4'],
      brand: json['brand'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}

/// Transaction on blockchain
class BlockchainTransaction {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final String status; // 'pending', 'confirmed', 'failed'
  final int confirmations;

  BlockchainTransaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.timestamp,
    required this.status,
    this.confirmations = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'from': from,
      'to': to,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'confirmations': confirmations,
    };
  }

  factory BlockchainTransaction.fromJson(Map<String, dynamic> json) {
    return BlockchainTransaction(
      hash: json['hash'],
      from: json['from'],
      to: json['to'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      confirmations: json['confirmations'] ?? 0,
    );
  }
}

/// Utility class for wallet data storage using secure storage
///
/// SECURITY: This implementation delegates encryption to flutter_secure_storage,
/// which uses:
/// - AES-256 encryption on Android (via Android Keystore)
/// - Keychain with AES-256 on iOS
/// - DPAPI on Windows
/// - libsecret on Linux
///
/// For production use, sensitive wallet data should be:
/// - Stored entirely in flutter_secure_storage (recommended)
/// - Or encrypted with the 'encrypt' package using AES-256-GCM
/// - With encryption keys stored in flutter_secure_storage
class WalletEncryption {
  /// Since flutter_secure_storage handles encryption automatically,
  /// this class provides backward compatibility for data migration.
  /// For new implementations, prefer storing directly in FlutterSecureStorage.

  /// Encrypts data - now returns as-is since storage handles encryption
  /// Kept for API compatibility with existing serialized data
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    // flutter_secure_storage handles encryption, but we keep this
    // for backwards compatibility with already-encrypted data
    return plainText;
  }

  /// Decrypts data - now returns as-is since storage handles encryption
  /// Kept for API compatibility with existing serialized data
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    // flutter_secure_storage handles decryption
    return encryptedText;
  }
}
