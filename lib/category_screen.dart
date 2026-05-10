import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/wallpaper.dart';
import 'payment_screen.dart';
import 'services/api_service.dart';
import 'wallpaper_preview.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<dynamic>> _screenFuture;

  @override
  void initState() {
    super.initState();
    _screenFuture = _loadScreenData();
  }

  Future<List<dynamic>> _loadScreenData() {
    return Future.wait([
      ApiService.getWallpapers(widget.category),
      _isPremiumUser(),
    ]);
  }

  Future<bool> _isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isPremium') ?? false;
  }

  void _refreshScreen() {
    setState(() {
      _screenFuture = _loadScreenData();
    });
  }

  Future<void> _openWallpaper(BuildContext context, Wallpaper wallpaper) async {
    // Always read the latest premium value when the user taps.
    // This avoids using an old cached value after payment verification.
    final latestPremiumStatus = await _isPremiumUser();

    if (!context.mounted) return;

    if (wallpaper.isPremium && !latestPremiumStatus) {
      final unlocked = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PaymentScreen()),
      );

      if (unlocked == true) {
        _refreshScreen();

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WallpaperPreview(imagePath: wallpaper.assetPath),
          ),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WallpaperPreview(imagePath: wallpaper.assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: FutureBuilder<List<dynamic>>(
        future: _screenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final wallpapers = snapshot.data![0] as List<Wallpaper>;
          final isPremiumUser = snapshot.data![1] as bool;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: wallpapers.length,
            itemBuilder: (_, index) {
              final wallpaper = wallpapers[index];
              final locked = wallpaper.isPremium && !isPremiumUser;

              return GestureDetector(
                onTap: () => _openWallpaper(context, wallpaper),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(wallpaper.assetPath, fit: BoxFit.cover),
                    ),
                    if (wallpaper.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                locked ? Icons.lock : Icons.lock_open,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text('Premium', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    if (locked)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
