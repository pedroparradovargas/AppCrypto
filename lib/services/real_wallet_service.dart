import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../models/blockchain_wallet.dart';

/// Servicio de billeteras reales usando librerias web3dart, bip39 y bip32.
///
/// Este servicio implementa la generacion real de billeteras HD (Hierarchical
/// Deterministic) siguiendo los estandares BIP-39, BIP-32 y BIP-44.
///
/// Flujo de generacion:
/// 1. Generar entropia criptografica segura
/// 2. Convertir entropia a mnemonic (BIP-39)
/// 3. Derivar seed desde mnemonic (PBKDF2)
/// 4. Crear master key desde seed (BIP-32)
/// 5. Derivar child keys usando BIP-44 path
/// 6. Obtener direccion Ethereum desde la clave publica
class RealWalletService {
  /// Clientes Web3 por red
  final Map<BlockchainNetwork, Web3Client> _web3Clients = {};

  /// Obtener o crear un cliente Web3 para la red especificada
  Web3Client _getClient(BlockchainNetwork network) {
    if (!_web3Clients.containsKey(network)) {
      _web3Clients[network] = Web3Client(
        network.rpcUrl,
        http.Client(),
      );
    }
    return _web3Clients[network]!;
  }

  /// Genera un mnemonic BIP-39 de 12 palabras con entropia criptografica segura
  ///
  /// Utiliza 128 bits de entropia para generar 12 palabras.
  /// Cada palabra representa 11 bits (128 + 4 bits checksum = 132 bits / 11 = 12 palabras).
  String generateMnemonic({int strength = 128}) {
    return bip39.generateMnemonic(strength: strength);
  }

  /// Valida que un mnemonic sea valido segun BIP-39
  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Deriva la seed desde un mnemonic usando PBKDF2 con 2048 iteraciones
  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    return bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  }

  /// Deriva una clave privada usando BIP-44 path
  ///
  /// BIP-44 path: m/44'/60'/0'/0/index
  /// - 44': Proposito (BIP-44)
  /// - 60': Coin type (60 = Ethereum, 966 = Polygon usa el mismo)
  /// - 0': Account
  /// - 0: Change (0 = external, 1 = internal)
  /// - index: Address index
  Uint8List derivePrivateKey(String mnemonic,
      {int index = 0, String passphrase = ''}) {
    final seed = mnemonicToSeed(mnemonic, passphrase: passphrase);
    final root = bip32.BIP32.fromSeed(seed);

    // BIP-44 derivation path for Ethereum
    final child = root.derivePath("m/44'/60'/0'/0/$index");

    return child.privateKey!;
  }

  /// Obtiene las credenciales Ethereum desde una clave privada
  EthPrivateKey getCredentials(Uint8List privateKey) {
    return EthPrivateKey(privateKey);
  }

  /// Obtiene la direccion Ethereum desde una clave privada
  Future<EthereumAddress> getAddress(Uint8List privateKey) async {
    final credentials = getCredentials(privateKey);
    return credentials.address;
  }

  /// Genera una billetera completa (mnemonic + private key + address)
  ///
  /// Retorna un [BlockchainWallet] con todos los datos necesarios para
  /// operar en la blockchain seleccionada.
  Future<BlockchainWallet> generateWallet(BlockchainNetwork network,
      {int strength = 128}) async {
    // 1. Generar mnemonic BIP-39
    final mnemonic = generateMnemonic(strength: strength);

    // 2. Derivar clave privada usando BIP-44
    final privateKeyBytes = derivePrivateKey(mnemonic);
    final privateKeyHex = HEX.encode(privateKeyBytes);

    // 3. Obtener direccion desde la clave privada
    final address = await getAddress(privateKeyBytes);

    return BlockchainWallet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      address: address.hexEip55,
      privateKey: '0x$privateKeyHex',
      mnemonic: mnemonic,
      network: network.name,
      balance: 0.0,
      createdAt: DateTime.now(),
      isBackedUp: false,
    );
  }

  /// Importa una billetera desde un mnemonic existente
  ///
  /// Valida el mnemonic y deriva la clave privada y direccion correspondientes.
  Future<BlockchainWallet> importFromMnemonic(
    String mnemonic,
    BlockchainNetwork network, {
    int accountIndex = 0,
  }) async {
    // Validar mnemonic
    final normalizedMnemonic = mnemonic.trim().toLowerCase();
    if (!validateMnemonic(normalizedMnemonic)) {
      throw Exception(
          'Frase de recuperacion invalida. Verifica que las palabras sean correctas.');
    }

    // Derivar clave privada
    final privateKeyBytes =
        derivePrivateKey(normalizedMnemonic, index: accountIndex);
    final privateKeyHex = HEX.encode(privateKeyBytes);

    // Obtener direccion
    final address = await getAddress(privateKeyBytes);

    return BlockchainWallet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      address: address.hexEip55,
      privateKey: '0x$privateKeyHex',
      mnemonic: normalizedMnemonic,
      network: network.name,
      balance: 0.0,
      createdAt: DateTime.now(),
      isBackedUp: true,
    );
  }

  /// Importa una billetera desde una clave privada
  Future<BlockchainWallet> importFromPrivateKey(
    String privateKey,
    BlockchainNetwork network,
  ) async {
    String cleanKey = privateKey.trim();
    if (cleanKey.startsWith('0x')) {
      cleanKey = cleanKey.substring(2);
    }

    if (cleanKey.length != 64) {
      throw Exception('Clave privada invalida: debe tener 64 caracteres hex.');
    }

    final privateKeyBytes = Uint8List.fromList(HEX.decode(cleanKey));
    final address = await getAddress(privateKeyBytes);

    return BlockchainWallet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      address: address.hexEip55,
      privateKey: '0x$cleanKey',
      mnemonic: '',
      network: network.name,
      balance: 0.0,
      createdAt: DateTime.now(),
      isBackedUp: true,
    );
  }

  /// Consulta el balance real de una direccion en la blockchain
  Future<double> getBalance(
      String address, BlockchainNetwork network) async {
    try {
      final client = _getClient(network);
      final ethAddress = EthereumAddress.fromHex(address);
      final balance = await client.getBalance(ethAddress);

      // Convertir de Wei a Ether (1 ETH = 10^18 Wei)
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      throw Exception('Error al consultar balance: $e');
    }
  }

  /// Envia una transaccion real en la blockchain
  ///
  /// Firma la transaccion con la clave privada y la envia a la red.
  Future<String> sendTransaction({
    required String privateKey,
    required String toAddress,
    required double amountInEther,
    required BlockchainNetwork network,
    int? gasLimit,
    BigInt? gasPrice,
  }) async {
    try {
      final client = _getClient(network);

      // Obtener credenciales
      String cleanKey = privateKey;
      if (cleanKey.startsWith('0x')) {
        cleanKey = cleanKey.substring(2);
      }
      final credentials =
          EthPrivateKey(Uint8List.fromList(HEX.decode(cleanKey)));

      // Obtener chain ID
      final chainId = await client.getChainId();

      // Estimar gas si no se proporciona
      final estimatedGas = gasLimit ?? 21000;

      // Enviar transaccion
      final txHash = await client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(toAddress),
          value: EtherAmount.fromBigInt(
            EtherUnit.wei,
            BigInt.from(amountInEther * 1e18),
          ),
          maxGas: estimatedGas,
        ),
        chainId: chainId.toInt(),
      );

      return txHash;
    } catch (e) {
      throw Exception('Error al enviar transaccion: $e');
    }
  }

  /// Estima el costo de gas para una transaccion
  Future<BigInt> estimateGas({
    required String fromAddress,
    required String toAddress,
    required double amountInEther,
    required BlockchainNetwork network,
  }) async {
    try {
      final client = _getClient(network);
      final gasEstimate = await client.estimateGas(
        sender: EthereumAddress.fromHex(fromAddress),
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(
          EtherUnit.wei,
          BigInt.from(amountInEther * 1e18),
        ),
      );
      return gasEstimate;
    } catch (e) {
      throw Exception('Error al estimar gas: $e');
    }
  }

  /// Obtiene el precio actual del gas en la red
  Future<EtherAmount> getGasPrice(BlockchainNetwork network) async {
    try {
      final client = _getClient(network);
      return await client.getGasPrice();
    } catch (e) {
      throw Exception('Error al obtener precio de gas: $e');
    }
  }

  /// Obtiene el numero de transacciones de una direccion (nonce)
  Future<int> getTransactionCount(
      String address, BlockchainNetwork network) async {
    try {
      final client = _getClient(network);
      return await client.getTransactionCount(
        EthereumAddress.fromHex(address),
      );
    } catch (e) {
      throw Exception('Error al obtener nonce: $e');
    }
  }

  /// Deriva multiples direcciones desde un mismo mnemonic
  ///
  /// Util para mostrar varias cuentas derivadas del mismo seed.
  Future<List<Map<String, String>>> deriveMultipleAddresses(
    String mnemonic, {
    int count = 5,
  }) async {
    final addresses = <Map<String, String>>[];

    for (int i = 0; i < count; i++) {
      final privateKeyBytes = derivePrivateKey(mnemonic, index: i);
      final privateKeyHex = HEX.encode(privateKeyBytes);
      final address = await getAddress(privateKeyBytes);

      addresses.add({
        'index': i.toString(),
        'address': address.hexEip55,
        'privateKey': '0x$privateKeyHex',
      });
    }

    return addresses;
  }

  /// Libera recursos de los clientes Web3
  void dispose() {
    for (final client in _web3Clients.values) {
      client.dispose();
    }
    _web3Clients.clear();
  }
}
