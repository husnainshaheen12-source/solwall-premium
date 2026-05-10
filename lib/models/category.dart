class WallpaperCategory {
  final String name;
  final String thumbnailAssetPath;

  WallpaperCategory({required this.name, required this.thumbnailAssetPath});

  factory WallpaperCategory.fromJson(Map<String, dynamic> json) {
    return WallpaperCategory(
      name: json['name'] as String,
      thumbnailAssetPath: json['thumbnail_asset_path'] as String,
    );
  }
}
