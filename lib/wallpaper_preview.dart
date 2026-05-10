import 'package:flutter/material.dart';

class WallpaperPreview extends StatelessWidget {
  final String imagePath;

  const WallpaperPreview({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Center(child: Image.asset(imagePath)),
    );
  }
}
