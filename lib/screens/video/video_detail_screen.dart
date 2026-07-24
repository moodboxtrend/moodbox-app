import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import 'video_reels_screen.dart';

class VideoDetailScreen extends StatelessWidget {
  final PostModel post;
  const VideoDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return VideoReelsScreen(
      initialPostId: post.id,
      posts: [post],
    );
  }
}
