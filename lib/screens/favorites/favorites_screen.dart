import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/category_model.dart';
import '../../models/post_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/category_card.dart';
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

// ── Dynamic tab model ─────────────────────────────────────────────────────────

class _DynTab {
  final String label;
  final String emoji;
  final List<Color> colors;
  final CategoryModel? category; // null = 'All'

  _DynTab({
    required this.label,
    required this.emoji,
    required this.colors,
    this.category,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _postService = PostService();
  List<PostModel>? _posts;
  String? _error;
  Set<String>? _lastIds;

  TabController? _tabCtrl;
  int _lastTabLength = 0;

  void _syncTabController(int length) {
    if (_tabCtrl == null || _lastTabLength != length) {
      _tabCtrl?.dispose();
      _tabCtrl = TabController(length: length, vsync: this);
      _lastTabLength = length;
      _tabCtrl!.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load(Set<String> ids) async {
    if (ids.isEmpty) {
      setState(() {
        _posts = [];
        _error = null;
      });
      return;
    }
    setState(() => _error = null);
    try {
      final result =
          await _postService.getPosts(ids: ids.toList(), limit: 100);
      if (mounted) setState(() => _posts = result.items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Filter saved posts by a specific DB category.
  List<PostModel> _filterForCategory(
      List<PostModel> posts, CategoryModel cat) {
    final byId = posts.where((p) => p.categoryId == cat.id).toList();
    if (byId.isNotEmpty) return byId;

    if (cat.type.isNotEmpty && cat.type != 'general') {
      return posts.where((p) => p.contentType == cat.type).toList();
    }
    return [];
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
    final theme = Theme.of(context);
    final dbCategories = context.watch<CategoryProvider>().categories;

    // ── Dynamic tabs from DB categories ───────────────────────────────────────
    final tabs = <_DynTab>[
      _DynTab(
        label: 'All',
        emoji: '🎁',
        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        category: null,
      ),
      ...dbCategories.map((c) {
        final emoji = resolveEmoji(c.emoji, c.type);
        final colors = AppColors.gradientFromHex(c.color, c.type);
        return _DynTab(
            label: c.name, emoji: emoji, colors: colors, category: c);
      }),
    ];

    _syncTabController(tabs.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildTabBar(theme, tabs),
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favorites, _) {
          if (!favorites.isLoaded) {
            return const PostListShimmer();
          }

          if (_lastIds == null ||
              !_setEquals(_lastIds!, favorites.favoriteIds)) {
            _lastIds = Set.of(favorites.favoriteIds);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _load(favorites.favoriteIds),
            );
          }

          if (favorites.favoriteIds.isEmpty) {
            return const EmptyStateView(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved posts yet',
              description:
                  'Tap the bookmark icon on any post to save it here.',
            );
          }

          if (_error != null) {
            return ErrorStateView(
              message: _error!,
              onRetry: () => _load(favorites.favoriteIds),
            );
          }

          if (_posts == null) {
            return const PostListShimmer();
          }

          if (_tabCtrl == null) return const PostListShimmer();

          return TabBarView(
            controller: _tabCtrl,
            children: tabs.map((tab) {
              return _buildSavedTabContent(context, _posts!, tab);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSavedTabContent(
      BuildContext context, List<PostModel> posts, _DynTab tab) {
    final filtered = tab.category == null
        ? posts
        : _filterForCategory(posts, tab.category!);

    if (filtered.isEmpty) {
      return EmptyStateView(
        icon: Icons.bookmark_border_rounded,
        title: tab.category == null
            ? 'No saved posts yet'
            : 'No saved ${tab.label} yet',
        description: tab.category == null
            ? 'Tap the bookmark icon on any post to save it here.'
            : 'Save some ${tab.label} content and it will appear here.',
      );
    }

    // ── Specific category tab ────────────────────────────────────────────────
    if (tab.category != null) {
      final type = tab.category!.type;
      final catName = tab.category!.name.toLowerCase();

      // Quotes category tab
      if (catName.contains('quote') || catName.contains('motivat')) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final post = filtered[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuoteReelsScreen(
                    initialPostId: post.id,
                    posts: filtered,
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
        );
      }

      // Wallpaper category tab
      if (type == AppConstants.typeWallpaper) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final post = filtered[index];
            return WallpaperCard(
              post: post,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => WallpaperDetailScreen(post: post)),
              ),
            );
          },
        );
      }

      // Video category tab
      if (type == AppConstants.typeVideo) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final post = filtered[index];
            return WallpaperCard(
              post: post,
              showPlayIcon: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoReelsScreen(
                    initialPostId: post.id,
                    posts: filtered,
                  ),
                ),
              ),
            );
          },
        );
      }

      // Recipe category tab
      if (type == AppConstants.typeRecipe) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = filtered[index];
            return PostCard(
              post: post,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(post: post)),
              ),
            );
          },
        );
      }

      // Story, Joke, or General tab
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = filtered[index];
          return PostCard(
            post: post,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(post: post)),
            ),
          );
        },
      );
    }

    // ── 'All' Tab: Group by content type sections ────────────────────────────
    final stories =
        filtered.where((p) => p.contentType == AppConstants.typeStory).toList();
    final recipes =
        filtered.where((p) => p.contentType == AppConstants.typeRecipe).toList();
    final jokes =
        filtered.where((p) => p.contentType == AppConstants.typeJoke).toList();
    final videos =
        filtered.where((p) => p.contentType == AppConstants.typeVideo).toList();

    final quotes = filtered.where((p) {
      if (stories.contains(p) ||
          recipes.contains(p) ||
          jokes.contains(p) ||
          videos.contains(p)) {
        return false;
      }
      return _isQuote(p);
    }).toList();

    final wallpapers = filtered.where((p) {
      if (stories.contains(p) ||
          recipes.contains(p) ||
          jokes.contains(p) ||
          videos.contains(p) ||
          quotes.contains(p)) {
        return false;
      }
      return p.contentType == AppConstants.typeWallpaper;
    }).toList();

    final others = filtered.where((p) {
      return !stories.contains(p) &&
          !recipes.contains(p) &&
          !jokes.contains(p) &&
          !videos.contains(p) &&
          !quotes.contains(p) &&
          !wallpapers.contains(p);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stories.isNotEmpty) ...[
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
          if (recipes.isNotEmpty) ...[
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
          if (jokes.isNotEmpty) ...[
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
          if (quotes.isNotEmpty) ...[
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
          if (wallpapers.isNotEmpty) ...[
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
          if (videos.isNotEmpty) ...[
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
          if (others.isNotEmpty) ...[
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

  Widget _buildTabBar(ThemeData theme, List<_DynTab> tabs) {
    if (_tabCtrl == null) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final isSelected = _tabCtrl!.index == i;

          return GestureDetector(
            onTap: () => _tabCtrl!.animateTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: tab.colors)
                    : null,
                color: isSelected
                    ? null
                    : theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
