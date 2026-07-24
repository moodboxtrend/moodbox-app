import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/category_model.dart';

/// Returns the emoji string for a content type.
String emojiForType(String type) {
  switch (type) {
    case AppConstants.typeJoke:     return '😂';
    case AppConstants.typeRecipe:   return '🍲';
    case AppConstants.typeStory:    return '📚';
    case AppConstants.typeWallpaper: return '🖼️';
    case AppConstants.typeVideo:    return '▶️';
    default:                        return '🎁';
  }
}

/// Resolves the best emoji for a category:
/// - Returns the DB emoji if it's not the generic default '🎁'
/// - Falls back to emojiForType(type) if the DB emoji is empty or generic
String resolveEmoji(String dbEmoji, String type) {
  if (dbEmoji.isNotEmpty && dbEmoji != '🎁') return dbEmoji;
  return emojiForType(type);
}


IconData iconForCategoryType(String type) {
  switch (type) {
    case AppConstants.typeJoke:      return Icons.emoji_emotions_outlined;
    case AppConstants.typeRecipe:    return Icons.restaurant_menu_outlined;
    case AppConstants.typeStory:     return Icons.menu_book_outlined;
    case AppConstants.typeWallpaper: return Icons.wallpaper_outlined;
    case AppConstants.typeVideo:     return Icons.play_circle_outline_rounded;
    default:                         return Icons.category_outlined;
  }
}

// ── Large gradient card for the Home screen 3-category row ───────────────────

class HomeCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const HomeCategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.gradientFromHex(category.color, category.type);
    final emoji = resolveEmoji(category.emoji, category.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              top: -12,
              right: -12,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid / Explore card (existing style, upgraded with gradient icon bg) ──────

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.gradientFromHex(category.color, category.type);
    final emoji = resolveEmoji(category.emoji, category.type);


    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
