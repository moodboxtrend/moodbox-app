import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'network_image_safe.dart';
import 'video_frame_preview.dart';

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
    final thumbUrl = post.resolvedThumbnailUrl;
    final videoUrl = post.videoDetails?.videoUrl ?? '';

    Widget backgroundWidget;
    if (thumbUrl.isNotEmpty) {
      backgroundWidget = NetworkImageSafe(
        url: thumbUrl,
        borderRadius: BorderRadius.circular(18),
      );
    } else if (videoUrl.isNotEmpty) {
      backgroundWidget = VideoFramePreview(
        videoUrl: videoUrl,
        borderRadius: BorderRadius.circular(18),
      );
    } else {
      backgroundWidget = NetworkImageSafe(
        url: '',
        borderRadius: BorderRadius.circular(18),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            backgroundWidget,
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

