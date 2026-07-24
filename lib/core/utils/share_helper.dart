import 'package:share_plus/share_plus.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class ShareHelper {
  ShareHelper._();

  /// Shares a post as plain text (title + short description). There is no
  /// public website, so we don't build a deep link - just readable text.
  static Future<void> sharePost(PostModel post) async {
    final buffer = StringBuffer(post.title);
    if (post.shortDescription.isNotEmpty) {
      buffer.write('\n\n${post.shortDescription}');
    }
    buffer.write('\n\nShared from MoodBox');

    await Share.share(buffer.toString());
    // Fire-and-forget analytics ping, ignored if it fails.
    PostService().trackAction(post.id, 'share');
  }
}
