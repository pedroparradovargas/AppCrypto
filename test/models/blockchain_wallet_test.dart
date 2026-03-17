import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_flutter/models/blockchain_wallet.dart';

void main() {
  group('BlockchainWallet Model', () {
    test('creates wallet with required fields', () {
      final wallet = BlockchainWallet(
        id: 'wallet-1',
        address: '0x1234567890abcdef',
        privateKey: 'private-key-123',
        mnemonic: 'word1 word2 word3',
        network: 'ethereum',
        createdAt: DateTime(2026, 3, 1),
      );

      expect(wallet.id, 'wallet-1');
      expect(wallet.address, '0x1234567890abcdef');
      expect(wallet.network, 'ethereum');
      expect(wallet.balance, 0.0); // default
      expect(wallet.isBackedUp, false); // default
    });

    test('toJson and fromJson are symmetric', () {
      final original = BlockchainWallet(
        id: 'wallet-1',
        address: '0xabc123',
        privateKey: 'pk-test',
        mnemonic: 'abandon ability able',
        network: 'polygon',
        balance: 1.5,
        createdAt: DateTime(2026, 3, 1),
        isBackedUp: true,
      );

      final json = original.toJson();
      final restored = BlockchainWallet.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.address, original.address);
      expect(restored.network, original.network);
      expect(restored.balance, original.balance);
      expect(restored.isBackedUp, original.isBackedUp);
    });

    test('copyWith updates specified fields', () {
      final wallet = BlockchainWallet(
        id: 'wallet-1',
        address: '0xabc',
        privateKey: 'pk',
        mnemonic: 'test',
        network: 'ethereum',
        createdAt: DateTime(2026, 3, 1),
      );

      final updated = wallet.copyWith(balance: 5.0, isBackedUp: true);

      expect(updated.balance, 5.0);
      expect(updated.isBackedUp, true);
      expect(updated.id, 'wallet-1'); // unchanged
      expect(updated.network, 'ethereum'); // unchanged
    });

    test('fromJson handles null balance', () {
      final json = {
        'id': 'wallet-1',
        'address': '0xabc',
        'privateKey': 'pk',
        'mnemonic': 'test',
        'network': 'ethereum',
        'balance': null,
        'createdAt': '2026-03-01T00:00:00.000',
        'isBackedUp': null,
      };

      final wallet = BlockchainWallet.fromJson(json);

      expect(wallet.balance, 0.0);
      expect(wallet.isBackedUp, false);
    });
  });

  group('BlockchainNetwork Enum', () {
    test('has three networks', () {
      expect(BlockchainNetwork.values.length, 3);
    });

    test('ethereum has correct properties', () {
      expect(BlockchainNetwork.ethereum.name, 'Ethereum');
      expect(BlockchainNetwork.ethereum.symbol, 'ETH');
    });

    test('polygon has correct properties', () {
      expect(BlockchainNetwork.polygon.name, 'Polygon');
      expect(BlockchainNetwork.polygon.symbol, 'MATIC');
    });

    test('binanceSmartChain has correct properties', () {
      expect(BlockchainNetwork.binanceSmartChain.name, 'BNB Chain');
      expect(BlockchainNetwork.binanceSmartChain.symbol, 'BNB');
    });
  });

  group('PaymentMethod Model', () {
    test('fromJson creates a valid PaymentMethod', () {
      final json = {
        'id': 'pm-1',
        'type': 'card',
        'last4': '4242',
        'brand': 'Visa',
        'isDefault': true,
      };

      final pm = PaymentMethod.fromJson(json);

      expect(pm.id, 'pm-1');
      expect(pm.type, 'card');
      expect(pm.last4, '4242');
      expect(pm.brand, 'Visa');
      expect(pm.isDefault, true);
    });

    test('toJson and fromJson are symmetric', () {
      final original = PaymentMethod(
        id: 'pm-2',
        type: 'card',
        last4: '1234',
        brand: 'Mastercard',
        isDefault: false,
      );

      final json = original.toJson();
      final restored = PaymentMethod.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.last4, original.last4);
      expect(restored.brand, original.brand);
    });
  });

  group('BlockchainTransaction Model', () {
    test('fromJson creates a valid transaction', () {
      final json = {
        'hash': '0xhash123',
        'from': '0xfrom',
        'to': '0xto',
        'amount': 1.5,
        'currency': 'ETH',
        'timestamp': '2026-03-01T10:00:00.000',
        'status': 'confirmed',
        'confirmations': 12,
      };

      final tx = BlockchainTransaction.fromJson(json);

      expect(tx.hash, '0xhash123');
      expect(tx.amount, 1.5);
      expect(tx.status, 'confirmed');
      expect(tx.confirmations, 12);
    });

    test('toJson and fromJson are symmetric', () {
      final original = BlockchainTransaction(
        hash: '0xtest',
        from: '0xsender',
        to: '0xreceiver',
        amount: 2.0,
        currency: 'MATIC',
        timestamp: DateTime(2026, 3, 5),
        status: 'pending',
        confirmations: 0,
      );

      final json = original.toJson();
      final restored = BlockchainTransaction.fromJson(json);

      expect(restored.hash, original.hash);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.status, original.status);
    });
  });

  group('WalletEncryption', () {
    test('encrypt returns same string (storage handles encryption)', () {
      expect(WalletEncryption.encrypt('test'), 'test');
    });

    test('decrypt returns same string (storage handles decryption)', () {
      expect(WalletEncryption.decrypt('test'), 'test');
    });

    test('encrypt handles empty string', () {
      expect(WalletEncryption.encrypt(''), '');
    });

    test('decrypt handles empty string', () {
      expect(WalletEncryption.decrypt(''), '');
    });
  });
}
