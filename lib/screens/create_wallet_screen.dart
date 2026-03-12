import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/blockchain_wallet.dart';
import '../providers/blockchain_provider.dart';
import '../utils/responsive.dart';

/// Screen for creating and managing blockchain wallets
class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _importMnemonicController = TextEditingController();
  final _externalAddressController = TextEditingController();
  bool _showMnemonic = false;

  @override
  void dispose() {
    _importMnemonicController.dispose();
    _externalAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Wallet'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BlockchainProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Network selector
                _buildNetworkSelector(provider),
                SizedBox(height: Responsive.h(24)),

                // Create new wallet section
                _buildCreateSection(provider),
                SizedBox(height: Responsive.h(32)),

                // Import from mnemonic section
                _buildImportSection(provider),
                SizedBox(height: Responsive.h(32)),

                // Connect external wallet section
                _buildExternalWalletSection(provider),
                SizedBox(height: Responsive.h(32)),

                // Error message
                if (provider.error != null)
                  Container(
                    padding: EdgeInsets.all(Responsive.w(12)),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkSelector(BlockchainProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Network',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            Wrap(
              spacing: Responsive.w(8),
              runSpacing: Responsive.h(8),
              children: BlockchainNetwork.values.map((network) {
                final isSelected = provider.selectedNetwork == network;
                return ChoiceChip(
                  label: Text(
                    network.name,
                    style: TextStyle(fontSize: Responsive.sp(14)),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      provider.selectNetwork(network);
                    }
                  },
                  selectedColor: const Color(0xFF1E88E5).withOpacity(0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSection(BlockchainProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Wallet',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Generate a new blockchain wallet with a secure recovery phrase.',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
            ),
            SizedBox(height: Responsive.h(16)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoadingWallets
                    ? null
                    : () => _createNewWallet(provider),
                icon: provider.isLoadingWallets
                    ? SizedBox(
                        width: Responsive.sp(20),
                        height: Responsive.sp(20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  provider.isLoadingWallets
                      ? 'Creating...'
                      : 'Generate New Wallet',
                  style: TextStyle(fontSize: Responsive.sp(14)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection(BlockchainProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import from Recovery Phrase',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Import an existing wallet using your 12 or 24 word recovery phrase.',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: _importMnemonicController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your recovery phrase...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoadingWallets
                    ? null
                    : () => _importWallet(provider),
                icon: const Icon(Icons.import_export),
                label: Text(
                  'Import Wallet',
                  style: TextStyle(fontSize: Responsive.sp(14)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalWalletSection(BlockchainProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect External Wallet',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Connect to MetaMask, Trust Wallet, or other Web3 wallets.',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: _externalAddressController,
              decoration: InputDecoration(
                hintText: 'Enter wallet address (0x...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoadingWallets
                    ? null
                    : () => _connectExternalWallet(provider),
                icon: const Icon(Icons.link),
                label: Text(
                  'Connect Wallet',
                  style: TextStyle(fontSize: Responsive.sp(14)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewWallet(BlockchainProvider provider) async {
    final wallet = await provider.generateWallet();
    if (wallet != null && mounted) {
      _showWalletCreatedDialog(wallet);
    }
  }

  Future<void> _importWallet(BlockchainProvider provider) async {
    final mnemonic = _importMnemonicController.text.trim();
    if (mnemonic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recovery phrase')),
      );
      return;
    }

    final wallet = await provider.importWallet(mnemonic);
    if (wallet != null && mounted) {
      _importMnemonicController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet imported successfully!')),
      );
    }
  }

  Future<void> _connectExternalWallet(BlockchainProvider provider) async {
    final address = _externalAddressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address')),
      );
      return;
    }

    final wallet = await provider.connectExternalWallet(address);
    if (wallet != null && mounted) {
      _externalAddressController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet connected successfully!')),
      );
    }
  }

  void _showWalletCreatedDialog(BlockchainWallet wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Created!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your wallet has been created. Save your recovery phrase safely!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: Responsive.h(16)),
              Container(
                padding: EdgeInsets.all(Responsive.w(12)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recovery Phrase:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(_showMnemonic
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _showMnemonic = !_showMnemonic;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_showMnemonic)
                      Text(
                        wallet.mnemonic,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: Responsive.sp(12),
                        ),
                      )
                    else
                      const Text('**** **** **** **** **** ****'),
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(16)),
              const Text(
                'Address:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                wallet.address,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: Responsive.sp(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
