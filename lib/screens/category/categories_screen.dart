import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/category_card.dart';
import '../../widgets/state_placeholders.dart';
import 'category_posts_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    // ── Loading / error states ────────────────────────────────────────────────
    if (provider.status == LoadStatus.loading ||
        provider.status == LoadStatus.idle) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explore')),
        body: const PostListShimmer(),
      );
    }

    if (provider.status == LoadStatus.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explore')),
        body: ErrorStateView(
          message: provider.error ?? 'Failed to load categories',
          onRetry: () => provider.loadCategories(force: true),
        ),
      );
    }

    final dbCategories = provider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: dbCategories.isEmpty
          ? const EmptyStateView(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              description: 'Check back soon for new content.',
            )
          : RefreshIndicator(
              onRefresh: () => provider.loadCategories(force: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: dbCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CategoryListTile(
                  category: dbCategories[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoryPostsScreen(category: dbCategories[i]),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── List tile for a single category ──────────────────────────────────────────

class _CategoryListTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryListTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.gradientFromHex(category.color, category.type);
    final emoji = resolveEmoji(category.emoji, category.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
