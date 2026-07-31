import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'network_image_safe.dart';

/// Grid card used for Wallpapers and Videos feeds (Pinterest-style tile).
class WallpaperCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final bool showPlayIcon;

  const WallpaperCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showPlayIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageSafe(url: post.featuredImageUrl, borderRadius: BorderRadius.circular(18)),
            if (showPlayIcon)
              const Center(
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44),
              ),
          ],
        ),
      ),
    );
  }
}
