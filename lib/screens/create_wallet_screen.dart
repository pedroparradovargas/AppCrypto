import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/blockchain_wallet.dart';
import '../providers/blockchain_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Wallet'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BlockchainProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Network selector
                _buildNetworkSelector(provider),
                const SizedBox(height: 24),

                // Create new wallet section
                _buildCreateSection(provider),
                const SizedBox(height: 32),

                // Import from mnemonic section
                _buildImportSection(provider),
                const SizedBox(height: 32),

                // Connect external wallet section
                _buildExternalWalletSection(provider),
                const SizedBox(height: 32),

                // Error message
                if (provider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red.shade700),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Network',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: BlockchainNetwork.values.map((network) {
                final isSelected = provider.selectedNetwork == network;
                return ChoiceChip(
                  label: Text(network.name),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate a new blockchain wallet with a secure recovery phrase.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoadingWallets
                    ? null
                    : () => _createNewWallet(provider),
                icon: provider.isLoadingWallets
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(provider.isLoadingWallets
                    ? 'Creating...'
                    : 'Generate New Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import from Recovery Phrase',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import an existing wallet using your 12 or 24 word recovery phrase.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoadingWallets
                    ? null
                    : () => _importWallet(provider),
                icon: const Icon(Icons.import_export),
                label: const Text('Import Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect External Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect to MetaMask, Trust Wallet, or other Web3 wallets.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _externalAddressController,
              decoration: InputDecoration(
                hintText: 'Enter wallet address (0x...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoadingWallets
                    ? null
                    : () => _connectExternalWallet(provider),
                icon: const Icon(Icons.link),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your wallet has been created. Save your recovery phrase safely!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
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
                      style: const TextStyle(fontFamily: 'monospace'),
                    )
                  else
                    const Text('**** **** **** **** **** ****'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Address:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              wallet.address,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
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
