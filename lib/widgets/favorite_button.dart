import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';

class FavoriteButton extends StatelessWidget {
  final String postId;
  final bool allowSave;

  const FavoriteButton({super.key, required this.postId, this.allowSave = true});

  @override
  Widget build(BuildContext context) {
    if (!allowSave) return const SizedBox.shrink();

    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        final isFav = favorites.isFavorite(postId);
        return IconButton(
          onPressed: () => favorites.toggle(postId),
          icon: Icon(
            isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isFav ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: isFav ? 'Remove from favorites' : 'Save to favorites',
        );
      },
    );
  }
}
