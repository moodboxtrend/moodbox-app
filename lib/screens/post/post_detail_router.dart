import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../widgets/state_placeholders.dart';
import '../video/video_detail_screen.dart';
import '../wallpaper/wallpaper_detail_screen.dart';
import 'article_detail_screen.dart';
import 'recipe_detail_screen.dart';

/// Fetches a single post by id (this also increments its view count on the
/// backend) then renders the layout appropriate for its content type.
class PostDetailRouter extends StatefulWidget {
  final String postId;
  const PostDetailRouter({super.key, required this.postId});

  @override
  State<PostDetailRouter> createState() => _PostDetailRouterState();
}

class _PostDetailRouterState extends State<PostDetailRouter> {
  final _service = PostService();
  PostModel? _post;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final post = await _service.getPostById(widget.postId);
      if (mounted) setState(() => _post = post);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(message: _error!, onRetry: _load),
      );
    }

    if (_post == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_post!.contentType) {
      case AppConstants.typeRecipe:
        return RecipeDetailScreen(post: _post!);
      case AppConstants.typeWallpaper:
        return WallpaperDetailScreen(post: _post!);
      case AppConstants.typeVideo:
        return VideoDetailScreen(post: _post!);
      case AppConstants.typeJoke:
      case AppConstants.typeStory:
      default:
        return ArticleDetailScreen(post: _post!);
    }
  }
}
