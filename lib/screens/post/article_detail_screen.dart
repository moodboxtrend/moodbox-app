import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/share_helper.dart';
import '../../models/post_model.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/network_image_safe.dart';

/// Detail layout for Jokes and Stories - a straightforward article view.
class ArticleDetailScreen extends StatelessWidget {
  final PostModel post;
  const ArticleDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          FavoriteButton(postId: post.id, allowSave: post.allowSave),
          if (post.allowShare)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => ShareHelper.sharePost(post),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (post.featuredImageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: NetworkImageSafe(url: post.featuredImageUrl, borderRadius: BorderRadius.circular(20)),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(post.subcategoryName.isNotEmpty ? post.subcategoryName : post.categoryName)),
              if (post.jokeDetails?.language != null) Chip(label: Text(post.jokeDetails!.language!)),
              if (post.storyDetails?.storyType != null) Chip(label: Text(post.storyDetails!.storyType!)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 15, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('${post.views} views', style: theme.textTheme.labelMedium),
              const SizedBox(width: 14),
              Text(DateFormatter.readable(post.publishDate), style: theme.textTheme.labelMedium),
              if (post.storyDetails != null && post.storyDetails!.readingTime > 0) ...[
                const SizedBox(width: 14),
                Text('${post.storyDetails!.readingTime} min read', style: theme.textTheme.labelMedium),
              ],
            ],
          ),
          const Divider(height: 32),
          if (post.content.isNotEmpty)
            Html(
              data: post.content,
              style: {
                'body': Style(
                  fontSize: FontSize(15.5),
                  lineHeight: LineHeight(1.6),
                  color: theme.colorScheme.onSurface,
                  margin: Margins.zero,
                ),
              },
            )
          else if (post.shortDescription.isNotEmpty)
            Text(post.shortDescription, style: theme.textTheme.bodyMedium),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags
                  .map((tag) => Chip(
                        label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
