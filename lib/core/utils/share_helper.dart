import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class ShareHelper {
  ShareHelper._();

  static Future<void> sharePost(PostModel post) async {
    final playStoreUrl = await _getPlayStoreUrl();
    final message = StringBuffer()
      ..writeln(post.title)
      ..writeln();

    if (post.shortDescription.isNotEmpty) {
      message.writeln(post.shortDescription);
      message.writeln();
    }

    message.writeln('Discover this on MoodBox and enjoy more jokes, recipes, stories, wallpapers, and videos.');
    message.writeln('Open it on Play Store:');
    message.write(playStoreUrl);

    final text = message.toString();

    // 1. Check if post is a video post with a video URL
    if (post.contentType == 'video' || (post.videoDetails != null && post.videoDetails!.videoUrl.isNotEmpty)) {
      final videoUrl = post.videoDetails?.videoUrl ?? '';
      
      // Determine if it's a YouTube URL (which cannot be directly downloaded as raw MP4 file via HTTP)
      final isYoutube = PostModel.extractYoutubeId(videoUrl) != null ||
          videoUrl.contains('youtube.com') ||
          videoUrl.contains('youtu.be');

      if (videoUrl.isNotEmpty && !isYoutube) {
        final videoFile = await _downloadMedia(videoUrl, post.id, isVideo: true);
        if (videoFile != null) {
          await Share.shareXFiles(
            [videoFile],
            text: text,
            subject: post.title,
          );
          PostService().trackAction(post.id, 'share');
          return;
        }
      }
    }

    // 2. Share featured image / thumbnail (for image posts or fallback for YouTube/video download failure)
    final imageUrl = post.resolvedThumbnailUrl.isNotEmpty
        ? post.resolvedThumbnailUrl
        : post.featuredImageUrl;

    if (imageUrl.isNotEmpty) {
      final imageFile = await _downloadMedia(imageUrl, post.id, isVideo: false);
      if (imageFile != null) {
        await Share.shareXFiles(
          [imageFile],
          text: text,
          subject: post.title,
        );
        PostService().trackAction(post.id, 'share');
        return;
      }
    }

    // 3. Fallback to text-only share if media file download is unavailable
    await Share.share(text, subject: post.title);
    PostService().trackAction(post.id, 'share');
  }

  static Future<XFile?> _downloadMedia(String url, String postId, {required bool isVideo}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      String ext = isVideo ? 'mp4' : 'jpg';
      String mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

      if (isVideo) {
        final lower = url.toLowerCase();
        if (lower.contains('.mov')) {
          ext = 'mov';
          mimeType = 'video/quicktime';
        } else if (lower.contains('.webm')) {
          ext = 'webm';
          mimeType = 'video/webm';
        } else if (lower.contains('.mkv')) {
          ext = 'mkv';
          mimeType = 'video/x-matroska';
        } else if (lower.contains('.3gp')) {
          ext = '3gp';
          mimeType = 'video/3gpp';
        }
      } else {
        final lower = url.toLowerCase();
        if (lower.contains('.png')) {
          ext = 'png';
          mimeType = 'image/png';
        } else if (lower.contains('.webp')) {
          ext = 'webp';
          mimeType = 'image/webp';
        } else if (lower.contains('.gif')) {
          ext = 'gif';
          mimeType = 'image/gif';
        }
      }

      final fileName = 'moodbox_share_${postId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final sharePath = '${tempDir.path}/$fileName';

      await Dio().download(url, sharePath);
      final file = File(sharePath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return XFile(sharePath, name: fileName, mimeType: mimeType);
      }
    } catch (_) {
      // ignore download errors and return null for fallback
    }
    return null;
  }

  static Future<String> _getPlayStoreUrl() async {
    return AppConstants.playStoreUrl;
  }
}
