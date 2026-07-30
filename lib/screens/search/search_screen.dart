import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';
import '../../providers/post_list_controller.dart';
import '../../widgets/network_image_safe.dart';
import '../../widgets/post_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_placeholders.dart';
import '../../widgets/wallpaper_card.dart';
import '../post/article_detail_screen.dart';
import '../post/post_detail_router.dart';
import '../post/quote_reels_screen.dart';
import '../post/recipe_detail_screen.dart';
import '../video/video_reels_screen.dart';
import '../wallpaper/wallpaper_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  PostListController? _controller;
  String _selectedFilter = 'All';

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _controller = null;
          _selectedFilter = 'All';
        });
        return;
      }
      setState(() {
        _selectedFilter = 'All';
        _controller = PostListController(search: trimmed)..loadInitial();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isQuote(PostModel post) {
    final cat = post.categoryName.toLowerCase();
    final sub = post.subcategoryName.toLowerCase();
    final title = post.title.toLowerCase();
    return cat.contains('quote') ||
        sub.contains('quote') ||
        cat.contains('motivat') ||
        sub.contains('motivat') ||
        title.contains('quote');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search jokes, recipes, stories, quotes…',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: _controller == null
          ? const EmptyStateView(
              icon: Icons.search_rounded,
              title: 'Search MoodBox',
              description:
                  'Find jokes, recipes, stories, quotes, wallpapers and videos.',
            )
          : AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                final controller = _controller!;
                if (controller.status == LoadStatus.loading ||
                    controller.status == LoadStatus.idle) {
                  return const PostListShimmer();
                }
                if (controller.status == LoadStatus.error) {
                  return ErrorStateView(
                    message: controller.error ?? 'Search failed',
                    onRetry: controller.loadInitial,
                  );
                }
                if (controller.status == LoadStatus.empty) {
                  return const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                  );
                }

                final posts = controller.posts;
                return _buildCategorizedResults(context, posts);
              },
            ),
    );
  }

  Widget _buildCategorizedResults(BuildContext context, List<PostModel> posts) {
    final stories =
        posts.where((p) => p.contentType == AppConstants.typeStory).toList();
    final recipes =
        posts.where((p) => p.contentType == AppConstants.typeRecipe).toList();
    final jokes =
        posts.where((p) => p.contentType == AppConstants.typeJoke).toList();
    final videos =
        posts.where((p) => p.contentType == AppConstants.typeVideo).toList();

    final quotes = posts.where((p) {
      if (stories.contains(p) ||
          recipes.contains(p) ||
          jokes.contains(p) ||
          videos.contains(p)) {
        return false;
      }
      return _isQuote(p);
    }).toList();

    final wallpapers = posts.where((p) {
      if (stories.contains(p) ||
          recipes.contains(p) ||
          jokes.contains(p) ||
          videos.contains(p) ||
          quotes.contains(p)) {
        return false;
      }
      return p.contentType == AppConstants.typeWallpaper;
    }).toList();

    final others = posts.where((p) {
      return !stories.contains(p) &&
          !recipes.contains(p) &&
          !jokes.contains(p) &&
          !videos.contains(p) &&
          !quotes.contains(p) &&
          !wallpapers.contains(p);
    }).toList();

    final availableFilters = <String>['All'];
    if (stories.isNotEmpty) availableFilters.add('Stories');
    if (recipes.isNotEmpty) availableFilters.add('Recipes');
    if (jokes.isNotEmpty) availableFilters.add('Jokes');
    if (quotes.isNotEmpty) availableFilters.add('Quotes');
    if (wallpapers.isNotEmpty) availableFilters.add('Wallpapers');
    if (videos.isNotEmpty) availableFilters.add('Videos');
    if (others.isNotEmpty) availableFilters.add('Articles');

    if (!availableFilters.contains(_selectedFilter)) {
      _selectedFilter = 'All';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          if (availableFilters.length > 2) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final filterName = availableFilters[i];
                  final isSelected = _selectedFilter == filterName;
                  return ChoiceChip(
                    label: Text(
                      filterName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = filterName),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stories Section
          if ((_selectedFilter == 'All' || _selectedFilter == 'Stories') &&
              stories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Stories 📚'),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = stories[index];
                return PostCard(
                  post: post,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(post: post)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Recipes Section
          if ((_selectedFilter == 'All' || _selectedFilter == 'Recipes') &&
              recipes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Recipes 🍲'),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = recipes[index];
                return PostCard(
                  post: post,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(post: post)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Jokes Section
          if ((_selectedFilter == 'All' || _selectedFilter == 'Jokes') &&
              jokes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Jokes 😂'),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: jokes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = jokes[index];
                return PostCard(
                  post: post,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(post: post)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Quotes Section (Image Grid format)
          if ((_selectedFilter == 'All' || _selectedFilter == 'Quotes') &&
              quotes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Quotes 💬'),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: quotes.length,
              itemBuilder: (context, index) {
                final post = quotes[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuoteReelsScreen(
                        initialPostId: post.id,
                        posts: quotes,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: post.featuredImageUrl.isNotEmpty
                        ? NetworkImageSafe(
                            url: post.featuredImageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Theme.of(context).cardColor,
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                post.title,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Wallpapers Section
          if ((_selectedFilter == 'All' || _selectedFilter == 'Wallpapers') &&
              wallpapers.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Wallpapers 🖼️'),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.68,
              ),
              itemCount: wallpapers.length,
              itemBuilder: (context, index) {
                final post = wallpapers[index];
                return WallpaperCard(
                  post: post,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => WallpaperDetailScreen(post: post)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Videos Section
          if ((_selectedFilter == 'All' || _selectedFilter == 'Videos') &&
              videos.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Videos 🎬'),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.68,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final post = videos[index];
                return WallpaperCard(
                  post: post,
                  showPlayIcon: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoReelsScreen(
                        initialPostId: post.id,
                        posts: videos,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Other Articles Section
          if ((_selectedFilter == 'All' || _selectedFilter == 'Articles') &&
              others.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: 'Articles 📄'),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: others.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = others[index];
                return PostCard(
                  post: post,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => PostDetailRouter(postId: post.id)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
