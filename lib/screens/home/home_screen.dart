import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/paginated_response.dart';
import '../../models/post_model.dart';
import '../../providers/category_provider.dart';
import '../../models/banner_model.dart';
import '../../services/banner_service.dart';
import '../../services/post_service.dart';
import '../../widgets/category_card.dart';
import '../../widgets/post_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_placeholders.dart';
import '../category/categories_screen.dart';
import '../category/category_posts_screen.dart';
import '../post/post_detail_router.dart';
import '../search/search_screen.dart';

// ── Fallback banners (used when API is unavailable) ─────────────────────────

final _fallbackBanners = [
  BannerModel(
    id: '1',
    title: '',
    quoteText: '"A good laugh is sunshine in the house."',
    emoji: '😂',
    type: 'joke',
    bgGradientStart: '#1B1830',
    bgGradientEnd: '#2D2459',
    buttonText: 'Read Jokes 😂',
    order: 1,
  ),
  BannerModel(
    id: '2',
    title: '',
    quoteText: '"Cooking is love made visible."',
    emoji: '🍲',
    type: 'recipe',
    bgGradientStart: '#2A1828',
    bgGradientEnd: '#4A1D38',
    buttonText: 'Try Recipes 🍲',
    order: 2,
  ),
  BannerModel(
    id: '3',
    title: '',
    quoteText: '"A reader lives a thousand lives."',
    emoji: '📚',
    type: 'story',
    bgGradientStart: '#1A1C38',
    bgGradientEnd: '#252D5E',
    buttonText: 'Read Stories 📚',
    order: 3,
  ),
];

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _hexColor(String hex, Color fallback) {
  try {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return fallback;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postService = PostService();
  final _bannerService = BannerService();
  final _bannerPageController = PageController();

  List<BannerModel> _banners = _fallbackBanners;
  List<PostModel>? _trending;
  String? _error;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-rotate banner every 6 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 6));
      if (!mounted) return false;
      if (_banners.isNotEmpty && _bannerPageController.hasClients) {
        final next = (_bannerIndex + 1) % _banners.length;
        _bannerPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      return true;
    });
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _postService.getPosts(isTrending: true, limit: 10),
        _bannerService.getBanners().catchError((_) => <BannerModel>[]),
      ]);
      if (!mounted) return;
      final fetchedBanners = results[1] as List<BannerModel>;
      setState(() {
        _trending = (results[0] as PaginatedResponse<PostModel>).items;
        if (fetchedBanners.isNotEmpty) {
          _banners = fetchedBanners;
          _bannerIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _openSearch() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );

  void _openCategory(CategoryModel cat) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryPostsScreen(category: cat)),
      );

  void _openExplore() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<CategoryProvider>().categories;
    final homeCategories = categories.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildAppBar(theme)),

              // ── Banner Carousel (swipeable PageView) ────────────────────────
              if (_banners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _bannerPageController,
                        itemCount: _banners.length,
                        onPageChanged: (i) => setState(() => _bannerIndex = i),
                        itemBuilder: (context, index) {
                          final b = _banners[index];
                          final cat = categories.firstWhere(
                            (c) => c.type == b.type,
                            orElse: () => categories.isNotEmpty
                                ? categories.first
                                : CategoryModel(
                                    id: '', name: '', slug: '', type: '',
                                    description: '', icon: '', emoji: '🎁',
                                    color: '#6D4AFF', imageUrl: '', order: 0,
                                  ),
                          );
                          return _BannerSlide(
                            key: ValueKey(b.id),
                            banner: b,
                            onTap: () {
                              if (cat.id.isNotEmpty) _openCategory(cat);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // ── Dot indicator (if multiple banners) ───────────────────────
              if (_banners.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (i) {
                        final active = i == _bannerIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: active
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              // ── Categories row (Fixed 3 items) ───────────────────────────
              if (homeCategories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: 'Categories',
                      actionLabel: 'View All',
                      onAction: _openExplore,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (int i = 0; i < homeCategories.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 110,
                              child: HomeCategoryCard(
                                category: homeCategories[i],
                                onTap: () => _openCategory(homeCategories[i]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],

              // ── Trending Today ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: 'Trending Today 🔥',
                  ),
                ),
              ),

              if (_error != null)
                SliverToBoxAdapter(
                  child: ErrorStateView(message: _error!, onRetry: _load),
                )
              else if (_trending == null)
                const SliverToBoxAdapter(child: PostListShimmer())
              else if (_trending!.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateView(
                    icon: Icons.inbox_outlined,
                    title: 'No trending content yet',
                    description: 'Check back soon!',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _trending!.length,
                    itemBuilder: (_, i) {
                      final post = _trending![i];
                      return TrendingPostCard(
                        post: post,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PostDetailRouter(postId: post.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Logo image with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/moodbox.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF9C6FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🎁', style: TextStyle(fontSize: 18))),
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // MoodBox Name Text
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Mood',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w300,
                    fontSize: 22,
                  ),
                ),
                TextSpan(
                  text: 'Box',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Search icon
          IconButton(
            icon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface, size: 24),
            onPressed: _openSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Banner Slide Widget ───────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onTap;

  const _BannerSlide({super.key, required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final startColor = _hexColor(banner.bgGradientStart, AppColors.primary);
    final endColor = _hexColor(banner.bgGradientEnd, const Color(0xFF2D2459));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(banner.id),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: endColor.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.quoteText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        banner.buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              banner.emoji,
              style: const TextStyle(fontSize: 52),
            ),
          ],
        ),
      ),
    );
  }
}
