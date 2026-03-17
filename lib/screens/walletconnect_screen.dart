import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/walletconnect_service.dart';
import '../models/blockchain_wallet.dart';
import '../utils/responsive.dart';

/// Pantalla de conexion WalletConnect v2
///
/// Permite al usuario conectar billeteras externas como MetaMask,
/// Trust Wallet, Rainbow, etc. mediante el protocolo WalletConnect.
class WalletConnectScreen extends StatefulWidget {
  const WalletConnectScreen({Key? key}) : super(key: key);

  @override
  State<WalletConnectScreen> createState() => _WalletConnectScreenState();
}

class _WalletConnectScreenState extends State<WalletConnectScreen> {
  final WalletConnectService _wcService = WalletConnectService();
  String? _connectionUri;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _connectedAddress;
  String? _error;
  int _selectedChainId = 1; // Ethereum mainnet

  final List<Map<String, dynamic>> _supportedChains = [
    {'name': 'Ethereum', 'chainId': 1, 'icon': Icons.currency_bitcoin},
    {'name': 'Polygon', 'chainId': 137, 'icon': Icons.hexagon},
    {'name': 'BSC', 'chainId': 56, 'icon': Icons.monetization_on},
  ];

  @override
  void initState() {
    super.initState();
    _initializeWalletConnect();
  }

  Future<void> _initializeWalletConnect() async {
    _wcService.onDisplayUri = (uri) {
      setState(() {
        _connectionUri = uri;
      });
    };

    _wcService.onSessionConnect = (session) {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _connectedAddress = _wcService.connectedAddress;
        _error = null;
      });
    };

    _wcService.onSessionDisconnect = () {
      setState(() {
        _isConnected = false;
        _connectedAddress = null;
        _connectionUri = null;
      });
    };

    _wcService.onError = (error) {
      setState(() {
        _error = error;
        _isConnecting = false;
      });
    };

    // Inicializar con el Project ID de WalletConnect Cloud
    // En produccion, obtener del backend o variables de entorno
    await _wcService.initialize(
      projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
      appName: 'CryptoExchange',
      appDescription: 'Plataforma de trading de criptomonedas',
    );

    // Verificar si ya hay una sesion activa
    if (_wcService.isConnected) {
      setState(() {
        _isConnected = true;
        _connectedAddress = _wcService.connectedAddress;
      });
    }
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
      _connectionUri = null;
    });

    await _wcService.connect(
      chains: ['eip155:$_selectedChainId'],
    );
  }

  Future<void> _disconnect() async {
    await _wcService.disconnect();
  }

  Future<void> _signMessage() async {
    if (_connectedAddress == null) return;

    final signature = await _wcService.personalSign(
      message: 'Bienvenido a CryptoExchange!\n\nFirma este mensaje para verificar tu identidad.\n\nTimestamp: ${DateTime.now().toIso8601String()}',
      address: _connectedAddress!,
    );

    if (signature != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firma: ${signature.substring(0, 20)}...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _wcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('WalletConnect'),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),
            SizedBox(height: Responsive.h(24)),

            if (!_isConnected) ...[
              // Selector de red
              _buildNetworkSelector(),
              SizedBox(height: Responsive.h(24)),

              // Boton de conexion
              _buildConnectButton(),
              SizedBox(height: Responsive.h(24)),

              // URI para copiar/QR
              if (_connectionUri != null) _buildUriSection(),
            ] else ...[
              // Informacion de conexion
              _buildConnectedInfo(),
              SizedBox(height: Responsive.h(24)),

              // Acciones
              _buildActions(),
              SizedBox(height: Responsive.h(24)),

              // Boton de desconexion
              _buildDisconnectButton(),
            ],

            // Error
            if (_error != null) ...[
              SizedBox(height: Responsive.h(16)),
              _buildErrorCard(),
            ],

            SizedBox(height: Responsive.h(24)),

            // Billeteras compatibles
            _buildSupportedWallets(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.w(12)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.link, color: Colors.white, size: Responsive.sp(32)),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WalletConnect v2',
                  style: TextStyle(
                    fontSize: Responsive.sp(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  _isConnected
                      ? 'Billetera conectada'
                      : 'Conecta tu billetera externa',
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(12),
              vertical: Responsive.h(6),
            ),
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isConnected ? 'Conectado' : 'Desconectado',
              style: TextStyle(
                color: _isConnected ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: Responsive.sp(12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelector() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Red',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            Wrap(
              spacing: Responsive.w(8),
              runSpacing: Responsive.h(8),
              children: _supportedChains.map((chain) {
                final isSelected = _selectedChainId == chain['chainId'];
                return ChoiceChip(
                  avatar: Icon(
                    chain['icon'] as IconData,
                    size: Responsive.sp(18),
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  label: Text(chain['name'] as String),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: Responsive.sp(14),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedChainId = chain['chainId'] as int;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton.icon(
      onPressed: _isConnecting ? null : _connect,
      icon: _isConnecting
          ? SizedBox(
              width: Responsive.sp(20),
              height: Responsive.sp(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.link),
      label: Text(
        _isConnecting ? 'Conectando...' : 'Conectar Billetera',
        style: TextStyle(fontSize: Responsive.sp(16)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: Responsive.h(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUriSection() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'URI de Conexion',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Copia esta URI y pegala en tu billetera, o escanea el QR code.',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
            ),
            SizedBox(height: Responsive.h(12)),
            Container(
              padding: EdgeInsets.all(Responsive.w(12)),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _connectionUri!,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: Responsive.sp(12),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.grey, size: Responsive.sp(20)),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _connectionUri!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URI copiada al portapapeles'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedInfo() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.w(8)),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.greenAccent),
                ),
                SizedBox(width: Responsive.w(12)),
                Expanded(
                  child: Text(
                    'Billetera Conectada',
                    style: TextStyle(
                      fontSize: Responsive.sp(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(16)),
            _buildInfoRow('Direccion', _connectedAddress ?? 'N/A'),
            SizedBox(height: Responsive.h(8)),
            _buildInfoRow(
              'Red',
              _supportedChains
                      .where((c) =>
                          c['chainId'] == _wcService.connectedChainId)
                      .map((c) => c['name'] as String)
                      .firstOrNull ??
                  'Desconocida',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: Responsive.w(80),
          child: Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.sp(14),
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        if (label == 'Direccion')
          IconButton(
            icon: Icon(Icons.copy, color: Colors.grey, size: Responsive.sp(16)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Direccion copiada')),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acciones',
          style: TextStyle(
            fontSize: Responsive.sp(16),
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        SizedBox(height: Responsive.h(8)),
        Card(
          color: const Color(0xFF16213E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(Responsive.w(8)),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.blueAccent),
                ),
                title: Text(
                  'Firmar Mensaje',
                  style: TextStyle(color: Colors.white, fontSize: Responsive.sp(14)),
                ),
                subtitle: Text(
                  'Verifica tu identidad firmando un mensaje',
                  style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: Responsive.sp(16)),
                onTap: _signMessage,
              ),
              const Divider(color: Color(0xFF1A1A2E), height: 1),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(Responsive.w(8)),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download,
                      color: Colors.greenAccent),
                ),
                title: Text(
                  'Importar a CryptoExchange',
                  style: TextStyle(color: Colors.white, fontSize: Responsive.sp(14)),
                ),
                subtitle: Text(
                  'Agrega esta billetera a tu lista',
                  style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: Responsive.sp(16)),
                onTap: () {
                  final wallet = _wcService.toBlockchainWallet();
                  if (wallet != null) {
                    Navigator.pop(context, wallet);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectButton() {
    return OutlinedButton.icon(
      onPressed: _disconnect,
      icon: Icon(Icons.link_off, color: Colors.redAccent, size: Responsive.sp(20)),
      label: Text(
        'Desconectar Billetera',
        style: TextStyle(fontSize: Responsive.sp(16)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        padding: EdgeInsets.symmetric(vertical: Responsive.h(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(12)),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: Responsive.sp(20)),
          SizedBox(width: Responsive.w(8)),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.redAccent, fontSize: Responsive.sp(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedWallets() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billeteras Compatibles',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            Wrap(
              spacing: Responsive.w(12),
              runSpacing: Responsive.h(8),
              children: [
                _buildWalletChip('MetaMask', Icons.account_balance_wallet),
                _buildWalletChip('Trust Wallet', Icons.security),
                _buildWalletChip('Rainbow', Icons.color_lens),
                _buildWalletChip('Coinbase', Icons.currency_exchange),
                _buildWalletChip('Ledger Live', Icons.devices),
                _buildWalletChip('Phantom', Icons.blur_on),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletChip(String name, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: Responsive.sp(16), color: Colors.blueAccent),
      label: Text(
        name,
        style: TextStyle(color: Colors.white, fontSize: Responsive.sp(12)),
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
    );
  }
}
