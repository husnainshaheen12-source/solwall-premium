import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'login_screen.dart';
import 'models/category.dart';
import 'models/theme_button.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';
import 'services/api_service.dart';
import 'utils/auth.dart';

class HomeScreen extends StatelessWidget {
  final Function(bool) changeThemeMode;

  const HomeScreen({super.key, required this.changeThemeMode});

  Future<void> _logout(BuildContext context) async {
    await Auth.logout();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(changeThemeMode: changeThemeMode),
        ),
      );
    }
  }

  void _openPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
  toolbarHeight: 82,
  title: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'University of Management and Technology',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        'SolWall Premium',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        'Wallpaper App',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
        actions: [
          ThemeButton(changeThemeMode: changeThemeMode),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Blockchain Premium',
            onPressed: () => _openPayment(context),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: FutureBuilder<List<WallpaperCategory>>(
        future: ApiService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _BackendError(message: snapshot.error.toString());
          }

          final categories = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(category: category.name),
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          category.thumbnailAssetPath,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.black45,
                        ),
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BackendError extends StatelessWidget {
  final String message;
  const _BackendError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Rust backend is not reachable',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'Start the backend with: cd backend_rust && cargo run',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
