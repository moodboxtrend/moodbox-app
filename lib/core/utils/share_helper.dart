import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

    if (post.featuredImageUrl.isNotEmpty) {
      final imageFile = await _downloadFeaturedImage(post.featuredImageUrl, post.id);
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

    await Share.share(text, subject: post.title);
    PostService().trackAction(post.id, 'share');
  }

  static Future<XFile?> _downloadFeaturedImage(String imageUrl, String postId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sharePath = '${tempDir.path}/moodbox_share_$postId.jpg';
      await Dio().download(imageUrl, sharePath);
      final file = File(sharePath);
      if (file.existsSync()) {
        return XFile(sharePath, name: 'moodbox_share_$postId.jpg', mimeType: 'image/jpeg');
      }
    } catch (_) {
      // ignore download/share image failures and fall back to text-only sharing
    }
    return null;
  }

  static Future<String> _getPlayStoreUrl() async {
    return 'https://play.google.com/store';
  }
}
