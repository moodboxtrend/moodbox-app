import 'package:flutter/material.dart';
import '../../core/utils/share_helper.dart';
import '../../models/post_model.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/network_image_safe.dart';

class RecipeDetailScreen extends StatefulWidget {
  final PostModel post;
  const RecipeDetailScreen({super.key, required this.post});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final recipe = post.recipeDetails;

    final prepAndCook = (recipe?.prepTime ?? 0) + (recipe?.cookTime ?? 0);
    final timeStr = prepAndCook > 0 ? '$prepAndCook Min' : '${recipe?.prepTime ?? 0} Min';

    return Scaffold(
      appBar: AppBar(
        title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          // ── Featured Image ──────────────────────────────────────────────────
          if (post.featuredImageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: NetworkImageSafe(
                url: post.featuredImageUrl,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          const SizedBox(height: 16),

          // ── Title & Subcategory ──────────────────────────────────────────────
          if (post.subcategoryName.isNotEmpty || post.categoryName.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(
                  post.subcategoryName.isNotEmpty
                      ? post.subcategoryName
                      : post.categoryName,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (post.shortDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.shortDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          if (recipe != null) ...[
            const SizedBox(height: 20),

            // ── Quick Info Bar: 🕒 Time | 🍽️ Servings ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickInfoItem(
                    icon: Icons.access_time_rounded,
                    label: timeStr,
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.12),
                  ),
                  _QuickInfoItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: '${recipe.servings} Servings',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Ingredients / Steps Segmented Tab Bar ────────────────────────
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withOpacity(0.7),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Ingredients'),
                  Tab(text: 'Steps'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Content (Ingredients / Steps) ────────────────────────────
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final isIngredientsTab = _tabController.index == 0;

                if (isIngredientsTab) {
                  // Ingredients Tab View
                  if (recipe.ingredients.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No ingredients listed for this recipe.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: recipe.ingredients.map((ing) {
                      final name = ing.name.trim();
                      final qty = ing.quantity.trim();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (qty.isNotEmpty)
                                      TextSpan(
                                        text: ' – $qty',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  // Steps Tab View
                  if (recipe.steps.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No preparation steps listed for this recipe.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: recipe.steps.map((step) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${step.step}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.instruction,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),

            // ── Tips ────────────────────────────────────────────────────────
            if (recipe.tips.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        recipe.tips,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
