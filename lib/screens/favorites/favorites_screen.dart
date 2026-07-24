import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/post_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/category_card.dart';
import '../../widgets/post_card.dart';
import '../../widgets/state_placeholders.dart';
import '../post/post_detail_router.dart';

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
  /// Primary: match by categoryId (exact DB reference).
  /// Fallback: match by contentType == category.type (for general types).
  List<PostModel> _filterForCategory(
      List<PostModel> posts, CategoryModel cat) {
    // First try by categoryId
    final byId = posts.where((p) => p.categoryId == cat.id).toList();
    if (byId.isNotEmpty) return byId;

    // Fallback: match by contentType for known types
    if (cat.type.isNotEmpty && cat.type != 'general') {
      return posts.where((p) => p.contentType == cat.type).toList();
    }
    return [];
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

          // Re-fetch whenever the saved-id set actually changes.
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
              // ── Filtered list for this tab ──────────────────────────────
              final filtered = tab.category == null
                  ? _posts!
                  : _filterForCategory(_posts!, tab.category!);

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
                        builder: (_) => PostDetailRouter(postId: post.id),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
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
