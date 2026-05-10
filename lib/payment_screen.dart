import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'utils/auth.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _customerWalletController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _wallet;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await ApiService.getWallet();
      if (mounted) setState(() => _wallet = wallet);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<String?> _currentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentUser');
  }

  Future<void> _verifyPayment() async {
    final username = await _currentUsername();
    if (username == null || username.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.verifyPayment(
        username: username,
        customerWallet: _customerWalletController.text.trim(),
        transactionSignature: _signatureController.text.trim(),
      );

      await Auth.refreshCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Payment checked')),
      );
      if (result['is_premium'] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _customerWalletController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchantWallet = _wallet?['merchant_wallet']?.toString() ?? 'Loading...';
    final price = _wallet?['premium_price_sol']?.toString() ?? '0.05';

    return Scaffold(
      appBar: AppBar(title: const Text('Blockchain Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Unlock premium wallpapers using Solana blockchain payment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: $price SOL', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    const Text('Send payment to merchant wallet:'),
                    const SizedBox(height: 8),
                    SelectableText(merchantWallet),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: merchantWallet == 'Loading...'
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: merchantWallet));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Wallet address copied')),
                              );
                            },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy wallet address'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerWalletController,
              decoration: const InputDecoration(
                labelText: 'Your Solana wallet address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _signatureController,
              decoration: const InputDecoration(
                labelText: 'Transaction signature / hash',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _verifyPayment,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified),
              label: Text(_loading ? 'Checking blockchain...' : 'Verify blockchain payment'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Production note: the Rust backend verifies the Solana transaction through RPC. For local demo only, run backend with MOCK_BLOCKCHAIN_PAYMENTS=true.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
