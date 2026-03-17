import 'package:flutter_test/flutter_test.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto_flutter/services/real_wallet_service.dart';
import 'package:crypto_flutter/models/blockchain_wallet.dart';

void main() {
  late RealWalletService walletService;

  setUp(() {
    walletService = RealWalletService();
  });

  tearDown(() {
    walletService.dispose();
  });

  group('RealWalletService - Generacion de Mnemonic', () {
    test('generateMnemonic genera 12 palabras por defecto', () {
      final mnemonic = walletService.generateMnemonic();
      final words = mnemonic.split(' ');

      expect(words.length, 12);
    });

    test('generateMnemonic con strength 256 genera 24 palabras', () {
      final mnemonic = walletService.generateMnemonic(strength: 256);
      final words = mnemonic.split(' ');

      expect(words.length, 24);
    });

    test('generateMnemonic genera mnemonics diferentes cada vez', () {
      final mnemonic1 = walletService.generateMnemonic();
      final mnemonic2 = walletService.generateMnemonic();

      expect(mnemonic1, isNot(equals(mnemonic2)));
    });

    test('generateMnemonic genera mnemonic valido', () {
      final mnemonic = walletService.generateMnemonic();
      expect(walletService.validateMnemonic(mnemonic), true);
    });
  });

  group('RealWalletService - Validacion de Mnemonic', () {
    test('validateMnemonic retorna true para mnemonic valido', () {
      final mnemonic = walletService.generateMnemonic();
      expect(walletService.validateMnemonic(mnemonic), true);
    });

    test('validateMnemonic retorna false para mnemonic invalido', () {
      expect(walletService.validateMnemonic('word1 word2 word3'), false);
    });

    test('validateMnemonic retorna false para string vacio', () {
      expect(walletService.validateMnemonic(''), false);
    });

    test('validateMnemonic retorna false para palabras no BIP39', () {
      expect(
        walletService.validateMnemonic(
            'perro gato casa mesa silla cama piso techo pared ventana puerta carro'),
        false,
      );
    });
  });

  group('RealWalletService - Derivacion de Seed', () {
    test('mnemonicToSeed genera seed de 64 bytes', () {
      final mnemonic = walletService.generateMnemonic();
      final seed = walletService.mnemonicToSeed(mnemonic);

      expect(seed.length, 64);
    });

    test('mnemonicToSeed es determinista', () {
      final mnemonic = walletService.generateMnemonic();
      final seed1 = walletService.mnemonicToSeed(mnemonic);
      final seed2 = walletService.mnemonicToSeed(mnemonic);

      expect(seed1, equals(seed2));
    });

    test('mnemonicToSeed con passphrase diferente produce seed diferente', () {
      final mnemonic = walletService.generateMnemonic();
      final seed1 = walletService.mnemonicToSeed(mnemonic);
      final seed2 =
          walletService.mnemonicToSeed(mnemonic, passphrase: 'password');

      expect(seed1, isNot(equals(seed2)));
    });
  });

  group('RealWalletService - Derivacion de Clave Privada', () {
    test('derivePrivateKey genera clave de 32 bytes', () {
      final mnemonic = walletService.generateMnemonic();
      final privateKey = walletService.derivePrivateKey(mnemonic);

      expect(privateKey.length, 32);
    });

    test('derivePrivateKey es determinista para el mismo mnemonic', () {
      final mnemonic = walletService.generateMnemonic();
      final key1 = walletService.derivePrivateKey(mnemonic);
      final key2 = walletService.derivePrivateKey(mnemonic);

      expect(key1, equals(key2));
    });

    test('derivePrivateKey genera claves diferentes para indices diferentes',
        () {
      final mnemonic = walletService.generateMnemonic();
      final key0 = walletService.derivePrivateKey(mnemonic, index: 0);
      final key1 = walletService.derivePrivateKey(mnemonic, index: 1);

      expect(key0, isNot(equals(key1)));
    });

    test('derivePrivateKey genera claves diferentes para mnemonics diferentes',
        () {
      final mnemonic1 = walletService.generateMnemonic();
      final mnemonic2 = walletService.generateMnemonic();
      final key1 = walletService.derivePrivateKey(mnemonic1);
      final key2 = walletService.derivePrivateKey(mnemonic2);

      expect(key1, isNot(equals(key2)));
    });
  });

  group('RealWalletService - Direccion Ethereum', () {
    test('getAddress genera direccion valida de 42 caracteres', () async {
      final mnemonic = walletService.generateMnemonic();
      final privateKey = walletService.derivePrivateKey(mnemonic);
      final address = await walletService.getAddress(privateKey);

      expect(address.hexEip55.length, 42);
      expect(address.hexEip55.startsWith('0x'), true);
    });

    test('getAddress es determinista', () async {
      final mnemonic = walletService.generateMnemonic();
      final privateKey = walletService.derivePrivateKey(mnemonic);
      final address1 = await walletService.getAddress(privateKey);
      final address2 = await walletService.getAddress(privateKey);

      expect(address1.hexEip55, equals(address2.hexEip55));
    });
  });

  group('RealWalletService - Generacion de Billetera Completa', () {
    test('generateWallet crea billetera para Ethereum', () async {
      final wallet =
          await walletService.generateWallet(BlockchainNetwork.ethereum);

      expect(wallet.address.startsWith('0x'), true);
      expect(wallet.address.length, 42);
      expect(wallet.privateKey.startsWith('0x'), true);
      expect(wallet.mnemonic.split(' ').length, 12);
      expect(wallet.network, BlockchainNetwork.ethereum.name);
      expect(wallet.balance, 0.0);
      expect(wallet.isBackedUp, false);
    });

    test('generateWallet crea billetera para Polygon', () async {
      final wallet =
          await walletService.generateWallet(BlockchainNetwork.polygon);

      expect(wallet.address.startsWith('0x'), true);
      expect(wallet.network, BlockchainNetwork.polygon.name);
    });

    test('generateWallet crea billetera para BSC', () async {
      final wallet =
          await walletService.generateWallet(BlockchainNetwork.binanceSmartChain);

      expect(wallet.address.startsWith('0x'), true);
      expect(wallet.network, BlockchainNetwork.binanceSmartChain.name);
    });

    test('generateWallet genera billeteras unicas', () async {
      final wallet1 =
          await walletService.generateWallet(BlockchainNetwork.ethereum);
      final wallet2 =
          await walletService.generateWallet(BlockchainNetwork.ethereum);

      expect(wallet1.address, isNot(equals(wallet2.address)));
      expect(wallet1.mnemonic, isNot(equals(wallet2.mnemonic)));
      expect(wallet1.privateKey, isNot(equals(wallet2.privateKey)));
    });

    test('generateWallet con 24 palabras', () async {
      final wallet = await walletService.generateWallet(
        BlockchainNetwork.ethereum,
        strength: 256,
      );

      expect(wallet.mnemonic.split(' ').length, 24);
    });
  });

  group('RealWalletService - Importacion desde Mnemonic', () {
    test('importFromMnemonic restaura la misma direccion', () async {
      final wallet1 =
          await walletService.generateWallet(BlockchainNetwork.ethereum);
      final wallet2 = await walletService.importFromMnemonic(
        wallet1.mnemonic,
        BlockchainNetwork.ethereum,
      );

      expect(wallet2.address, wallet1.address);
      expect(wallet2.privateKey, wallet1.privateKey);
      expect(wallet2.isBackedUp, true);
    });

    test('importFromMnemonic lanza excepcion para mnemonic invalido',
        () async {
      expect(
        () => walletService.importFromMnemonic(
          'invalid mnemonic phrase here',
          BlockchainNetwork.ethereum,
        ),
        throwsException,
      );
    });

    test('importFromMnemonic maneja espacios extra', () async {
      final wallet =
          await walletService.generateWallet(BlockchainNetwork.ethereum);
      final mnemonicWithSpaces = '  ${wallet.mnemonic}  ';

      final imported = await walletService.importFromMnemonic(
        mnemonicWithSpaces,
        BlockchainNetwork.ethereum,
      );

      expect(imported.address, wallet.address);
    });
  });

  group('RealWalletService - Importacion desde Clave Privada', () {
    test('importFromPrivateKey crea billetera correctamente', () async {
      final wallet =
          await walletService.generateWallet(BlockchainNetwork.ethereum);

      final imported = await walletService.importFromPrivateKey(
        wallet.privateKey,
        BlockchainNetwork.ethereum,
      );

      expect(imported.address, wallet.address);
      expect(imported.mnemonic, '');
      expect(imported.isBackedUp, true);
    });

    test('importFromPrivateKey acepta clave sin prefijo 0x', () async {
      final wallet =
          await walletService.generateWallet(BlockchainNetwork.ethereum);
      final keyWithout0x = wallet.privateKey.substring(2);

      final imported = await walletService.importFromPrivateKey(
        keyWithout0x,
        BlockchainNetwork.ethereum,
      );

      expect(imported.address, wallet.address);
    });

    test('importFromPrivateKey lanza excepcion para clave invalida', () {
      expect(
        () => walletService.importFromPrivateKey(
          '0x123',
          BlockchainNetwork.ethereum,
        ),
        throwsException,
      );
    });
  });

  group('RealWalletService - Derivacion Multiple', () {
    test('deriveMultipleAddresses genera el numero correcto de direcciones',
        () async {
      final mnemonic = walletService.generateMnemonic();
      final addresses =
          await walletService.deriveMultipleAddresses(mnemonic, count: 3);

      expect(addresses.length, 3);
    });

    test('deriveMultipleAddresses genera direcciones unicas', () async {
      final mnemonic = walletService.generateMnemonic();
      final addresses =
          await walletService.deriveMultipleAddresses(mnemonic, count: 5);

      final uniqueAddresses =
          addresses.map((a) => a['address']).toSet();
      expect(uniqueAddresses.length, 5);
    });

    test('deriveMultipleAddresses contiene indice, direccion y clave',
        () async {
      final mnemonic = walletService.generateMnemonic();
      final addresses =
          await walletService.deriveMultipleAddresses(mnemonic, count: 1);

      expect(addresses.first.containsKey('index'), true);
      expect(addresses.first.containsKey('address'), true);
      expect(addresses.first.containsKey('privateKey'), true);
      expect(addresses.first['index'], '0');
      expect(addresses.first['address']!.startsWith('0x'), true);
      expect(addresses.first['privateKey']!.startsWith('0x'), true);
    });
  });
}
