import 'dart:convert';
import 'dart:typed_data';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:hex/hex.dart';
import '../models/blockchain_wallet.dart';

/// Servicio de integracion con WalletConnect v2.
///
/// Permite conectar billeteras externas (MetaMask, Trust Wallet, Rainbow, etc.)
/// a la aplicacion usando el protocolo WalletConnect v2.
///
/// Flujo de conexion:
/// 1. Inicializar Web3App con project ID de WalletConnect Cloud
/// 2. Crear una sesion de pairing (genera URI para QR)
/// 3. El usuario escanea el QR con su billetera
/// 4. Se establece la sesion y se obtiene la direccion
/// 5. Se pueden firmar transacciones y mensajes
///
/// Configuracion requerida:
/// - Project ID de WalletConnect Cloud (https://cloud.walletconnect.com)
class WalletConnectService {
  Web3App? _web3App;
  SessionData? _activeSession;

  // Callbacks
  Function(String uri)? onDisplayUri;
  Function(SessionData session)? onSessionConnect;
  Function()? onSessionDisconnect;
  Function(String error)? onError;

  /// Estado de la conexion
  bool get isConnected => _activeSession != null;

  /// Sesion activa
  SessionData? get activeSession => _activeSession;

  /// Direccion conectada
  String? get connectedAddress {
    if (_activeSession == null) return null;

    final accounts = _activeSession!.namespaces['eip155']?.accounts;
    if (accounts == null || accounts.isEmpty) return null;

    // Formato: eip155:1:0xabc...
    final parts = accounts.first.split(':');
    return parts.length >= 3 ? parts[2] : null;
  }

  /// Chain ID conectado
  int? get connectedChainId {
    if (_activeSession == null) return null;

    final accounts = _activeSession!.namespaces['eip155']?.accounts;
    if (accounts == null || accounts.isEmpty) return null;

    final parts = accounts.first.split(':');
    return parts.length >= 2 ? int.tryParse(parts[1]) : null;
  }

  /// Inicializa el servicio WalletConnect
  ///
  /// Requiere un Project ID de WalletConnect Cloud.
  Future<void> initialize({
    required String projectId,
    String appName = 'CryptoExchange',
    String appDescription = 'Plataforma de trading de criptomonedas',
    String appUrl = 'https://cryptoexchange.app',
    String appIcon = 'https://cryptoexchange.app/icon.png',
  }) async {
    try {
      _web3App = await Web3App.createInstance(
        projectId: projectId,
        metadata: PairingMetadata(
          name: appName,
          description: appDescription,
          url: appUrl,
          icons: [appIcon],
        ),
      );

      // Escuchar eventos de sesion
      _web3App!.onSessionConnect.subscribe(_onSessionConnect);
      _web3App!.onSessionDelete.subscribe(_onSessionDelete);

      // Restaurar sesiones existentes
      _restoreSession();
    } catch (e) {
      onError?.call('Error al inicializar WalletConnect: $e');
    }
  }

  /// Restaura una sesion existente si la hay
  void _restoreSession() {
    final sessions = _web3App?.sessions.getAll();
    if (sessions != null && sessions.isNotEmpty) {
      _activeSession = sessions.first;
      onSessionConnect?.call(_activeSession!);
    }
  }

  /// Inicia el proceso de conexion con una billetera externa
  ///
  /// Genera un URI que se puede mostrar como QR code o usar como deep link.
  /// El usuario debe escanear el QR con su billetera para conectarse.
  Future<String?> connect({
    List<String> chains = const ['eip155:1'],
    List<String> methods = const [
      'eth_sendTransaction',
      'eth_signTransaction',
      'eth_sign',
      'personal_sign',
      'eth_signTypedData',
    ],
    List<String> events = const [
      'chainChanged',
      'accountsChanged',
    ],
  }) async {
    if (_web3App == null) {
      onError?.call('WalletConnect no inicializado');
      return null;
    }

    try {
      final connectResponse = await _web3App!.connect(
        requiredNamespaces: {
          'eip155': RequiredNamespace(
            chains: chains,
            methods: methods,
            events: events,
          ),
        },
      );

      final uri = connectResponse.uri;
      if (uri != null) {
        onDisplayUri?.call(uri.toString());
      }

      // Esperar la aprobacion de la sesion
      final session = await connectResponse.session.future;
      _activeSession = session;
      onSessionConnect?.call(session);

      return uri?.toString();
    } catch (e) {
      onError?.call('Error al conectar: $e');
      return null;
    }
  }

  /// Desconecta la sesion activa
  Future<void> disconnect() async {
    if (_web3App == null || _activeSession == null) return;

    try {
      await _web3App!.disconnectSession(
        topic: _activeSession!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
      _activeSession = null;
      onSessionDisconnect?.call();
    } catch (e) {
      onError?.call('Error al desconectar: $e');
    }
  }

  /// Firma un mensaje personal (personal_sign)
  ///
  /// Util para verificar que el usuario controla la billetera.
  Future<String?> personalSign({
    required String message,
    required String address,
  }) async {
    if (_web3App == null || _activeSession == null) {
      onError?.call('No hay sesion activa');
      return null;
    }

    try {
      final messageHex = '0x${HEX.encode(utf8.encode(message))}';

      final result = await _web3App!.request(
        topic: _activeSession!.topic,
        chainId: 'eip155:${connectedChainId ?? 1}',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [messageHex, address],
        ),
      );

      return result as String?;
    } catch (e) {
      onError?.call('Error al firmar mensaje: $e');
      return null;
    }
  }

  /// Envia una transaccion a traves de la billetera conectada
  ///
  /// La billetera del usuario mostrara los detalles de la transaccion
  /// para que el usuario la apruebe o rechace.
  Future<String?> sendTransaction({
    required String from,
    required String to,
    required BigInt value,
    String? data,
    int? gasLimit,
    BigInt? gasPrice,
  }) async {
    if (_web3App == null || _activeSession == null) {
      onError?.call('No hay sesion activa');
      return null;
    }

    try {
      final txParams = {
        'from': from,
        'to': to,
        'value': '0x${value.toRadixString(16)}',
        if (data != null) 'data': data,
        if (gasLimit != null) 'gas': '0x${gasLimit.toRadixString(16)}',
        if (gasPrice != null)
          'gasPrice': '0x${gasPrice.toRadixString(16)}',
      };

      final result = await _web3App!.request(
        topic: _activeSession!.topic,
        chainId: 'eip155:${connectedChainId ?? 1}',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [txParams],
        ),
      );

      return result as String?;
    } catch (e) {
      onError?.call('Error al enviar transaccion: $e');
      return null;
    }
  }

  /// Firma datos tipados (EIP-712)
  ///
  /// Usado para firmar datos estructurados como ordenes de intercambio.
  Future<String?> signTypedData({
    required String address,
    required Map<String, dynamic> typedData,
  }) async {
    if (_web3App == null || _activeSession == null) {
      onError?.call('No hay sesion activa');
      return null;
    }

    try {
      final result = await _web3App!.request(
        topic: _activeSession!.topic,
        chainId: 'eip155:${connectedChainId ?? 1}',
        request: SessionRequestParams(
          method: 'eth_signTypedData',
          params: [address, jsonEncode(typedData)],
        ),
      );

      return result as String?;
    } catch (e) {
      onError?.call('Error al firmar datos tipados: $e');
      return null;
    }
  }

  /// Obtiene todas las sesiones activas
  List<SessionData> getActiveSessions() {
    return _web3App?.sessions.getAll() ?? [];
  }

  /// Convierte la sesion activa a un BlockchainWallet
  BlockchainWallet? toBlockchainWallet() {
    final address = connectedAddress;
    if (address == null) return null;

    final chainId = connectedChainId ?? 1;
    String networkName;
    switch (chainId) {
      case 1:
        networkName = BlockchainNetwork.ethereum.name;
        break;
      case 137:
        networkName = BlockchainNetwork.polygon.name;
        break;
      case 56:
        networkName = BlockchainNetwork.binanceSmartChain.name;
        break;
      default:
        networkName = BlockchainNetwork.ethereum.name;
    }

    return BlockchainWallet(
      id: 'wc_${_activeSession!.topic.substring(0, 8)}',
      address: address,
      privateKey: '', // WalletConnect no expone la clave privada
      mnemonic: '', // No disponible via WalletConnect
      network: networkName,
      balance: 0.0,
      createdAt: DateTime.now(),
      isBackedUp: true,
    );
  }

  // Callbacks internos

  void _onSessionConnect(SessionConnect? event) {
    if (event != null) {
      _activeSession = event.session;
      onSessionConnect?.call(event.session);
    }
  }

  void _onSessionDelete(SessionDelete? event) {
    _activeSession = null;
    onSessionDisconnect?.call();
  }

  /// Libera recursos
  void dispose() {
    _web3App?.onSessionConnect.unsubscribeAll();
    _web3App?.onSessionDelete.unsubscribeAll();
    _web3App = null;
    _activeSession = null;
  }
}
