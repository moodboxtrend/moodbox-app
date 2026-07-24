import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Cached network image with a shimmer placeholder and a graceful fallback
/// icon on error - used everywhere instead of raw Image.network.
class NetworkImageSafe extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageSafe({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(16);

    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: width,
          height: height,
          color: theme.colorScheme.primary.withOpacity(0.08),
          child: Icon(Icons.image_outlined, color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: theme.colorScheme.surface,
          highlightColor: theme.colorScheme.primary.withOpacity(0.08),
          child: Container(width: width, height: height, color: Colors.white),
        ),
        errorWidget: (context, _, __) => Container(
          width: width,
          height: height,
          color: theme.colorScheme.primary.withOpacity(0.08),
          child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
      ),
    );
  }
}
