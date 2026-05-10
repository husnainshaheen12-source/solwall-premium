class Wallpaper {
  final String id;
  final String category;
  final String assetPath;
  final bool isPremium;

  Wallpaper({
    required this.id,
    required this.category,
    required this.assetPath,
    required this.isPremium,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'] as String,
      category: json['category'] as String,
      assetPath: json['asset_path'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }
}
