import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../providers/post_list_controller.dart';
import '../../services/category_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/state_placeholders.dart';
import '../../widgets/wallpaper_card.dart';
import '../post/post_detail_router.dart';
import '../post/quote_reels_screen.dart';
import '../video/video_reels_screen.dart';

/// Shows subcategory filter chips + a paginated feed of posts within a
/// category. Grid layout for Wallpaper/Video, list layout for the rest.
///
/// Use [CategoryPostsScreen] for standalone navigation (has its own Scaffold/AppBar).
/// Use [CategoryPostsBody] for embedding inside a TabBarView (no Scaffold).
class CategoryPostsScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryPostsScreen({super.key, required this.category});

  @override
  State<CategoryPostsScreen> createState() => _CategoryPostsScreenState();
}

class _CategoryPostsScreenState extends State<CategoryPostsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: CategoryPostsBody(category: widget.category),
    );
  }
}

/// Embeddable body — no Scaffold, suitable for TabBarView.
class CategoryPostsBody extends StatefulWidget {
  final CategoryModel category;
  const CategoryPostsBody({super.key, required this.category});

  @override
  State<CategoryPostsBody> createState() => _CategoryPostsBodyState();
}

class _CategoryPostsBodyState extends State<CategoryPostsBody> {
  final _categoryService = CategoryService();
  final _scrollController = ScrollController();

  List<SubcategoryModel> _subcategories = [];
  String? _selectedSubcategoryId;
  late PostListController _controller;

  bool get _isGrid =>
      widget.category.type == AppConstants.typeWallpaper ||
      widget.category.type == AppConstants.typeVideo;

  @override
  void initState() {
    super.initState();
    _controller = PostListController(categoryId: widget.category.id)
      ..loadInitial();
    _scrollController.addListener(_onScroll);
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    try {
      final subs = await _categoryService.getSubcategories(
          categoryId: widget.category.id);
      if (mounted) setState(() => _subcategories = subs);
    } catch (_) {
      // Non-fatal
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _controller.loadMore();
    }
  }

  void _selectSubcategory(String? id) {
    if (_selectedSubcategoryId == id) return; // no-op if same selection
    _controller.dispose(); // dispose old before creating new
    setState(() {
      _selectedSubcategoryId = id;
      _controller = PostListController(
        categoryId: widget.category.id,
        subcategoryId: id,
      )..loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_subcategories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedSubcategoryId == null,
                    onSelected: (_) => _selectSubcategory(null),
                  ),
                ),
                ..._subcategories.map(
                  (sub) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sub.name),
                      selected: _selectedSubcategoryId == sub.id,
                      onSelected: (_) => _selectSubcategory(sub.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.status == LoadStatus.loading ||
                  _controller.status == LoadStatus.idle) {
                return _isGrid ? const GridShimmer() : const PostListShimmer();
              }
              if (_controller.status == LoadStatus.error) {
                return ErrorStateView(
                  message: _controller.error ?? 'Failed to load posts',
                  onRetry: _controller.loadInitial,
                );
              }
              if (_controller.status == LoadStatus.empty) {
                return const EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: 'Nothing here yet',
                  description:
                      'New content will show up here once it\'s published.',
                );
              }

              final posts = _controller.posts;

              // Apply image-only grid ONLY for Quotes category
              final isQuoteCategory = widget.category.name.toLowerCase().contains('quote') ||
                  widget.category.slug.toLowerCase().contains('quote');
              final imagePosts = posts
                  .where((p) => p.featuredImageUrl.isNotEmpty)
                  .toList();
              final showQuoteGrid = isQuoteCategory && imagePosts.isNotEmpty;

              if (showQuoteGrid) {
                // ── Image-only grid (quotes, motivational, etc.) ─────────────
                return RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: posts.length +
                        (_controller.status == LoadStatus.loadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= posts.length) {
                        return const SizedBox.shrink();
                      }
                      final post = posts[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuoteReelsScreen(
                              initialPostId: post.id,
                              posts: imagePosts,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            post.featuredImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.06),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.06),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 32),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              if (_isGrid) {
                return RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: posts.length +
                        (_controller.status == LoadStatus.loadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= posts.length) {
                        return const DecoratedBox(
                            decoration: BoxDecoration(), child: SizedBox());
                      }
                      final post = posts[index];
                      final isVideo =
                          widget.category.type == AppConstants.typeVideo;
                      return WallpaperCard(
                        post: post,
                        showPlayIcon: isVideo,
                        onTap: () {
                          if (isVideo) {
                            // Open reels player with all loaded videos so user
                            // can scroll to next/previous video.
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VideoReelsScreen(
                                  initialPostId: post.id,
                                  posts: posts,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PostDetailRouter(postId: post.id)),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= posts.length) {
                      return _controller.status == LoadStatus.loadingMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          : const SizedBox.shrink();
                    }
                    final post = posts[index];
                    return PostCard(
                      post: post,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => PostDetailRouter(postId: post.id)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
