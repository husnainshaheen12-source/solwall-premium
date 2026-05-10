import '../models/wallpaper.dart';

final wallpapersByCategory = {
  '3D': [
    Wallpaper(
      id: '3d-1',
      category: '3D',
      assetPath: 'assets/unnamed.png',
      isPremium: false,
    ),
    Wallpaper(
      id: '3d-2',
      category: '3D',
      assetPath: 'assets/images1.jpg',
      isPremium: true,
    ),
  ],
  'Nature': [
    Wallpaper(
      id: 'nature-1',
      category: 'Nature',
      assetPath: 'assets/0e41dd403eae76a2e5d4abc02934c54e.jpg',
      isPremium: false,
    ),
    Wallpaper(
      id: 'nature-2',
      category: 'Nature',
      assetPath: 'assets/de2d16a4d4683a4d783a73d671fd11a7.jpg',
      isPremium: true,
    ),
  ],
  'Anime': [
    Wallpaper(
      id: 'anime-1',
      category: 'Anime',
      assetPath: 'assets/yaqGvs.jpg',
      isPremium: false,
    ),
    Wallpaper(
      id: 'anime-2',
      category: 'Anime',
      assetPath: 'assets/43afd01dc42127c352f1fde070cc2be0.jpg',
      isPremium: true,
    ),
  ],
};
