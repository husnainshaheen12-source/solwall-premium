import 'package:flutter/material.dart';
import 'utils/auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = await Auth.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _fullNameController.text = user['full_name']?.toString() ?? '';
        _usernameController.text = user['username']?.toString() ?? '';
        _isPremium = user['is_premium'] == true;
      });
    }
  }

  Future<void> _saveDetails() async {
    await Auth.updateCurrentUser(
      _fullNameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(_isPremium ? Icons.verified : Icons.lock_outline),
              title: Text(_isPremium ? 'Premium unlocked' : 'Free account'),
              subtitle: const Text('Premium is controlled by Rust backend blockchain verification'),
            ),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              readOnly: true,
            ),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                helperText: 'Leave blank to keep current password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDetails,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Update Profile'),
            )
          ],
        ),
      ),
    );
  }
}
