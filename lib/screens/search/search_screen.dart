import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/post_list_controller.dart';
import '../../widgets/post_card.dart';
import '../../widgets/state_placeholders.dart';
import '../post/post_detail_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  PostListController? _controller;

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() => _controller = null);
        return;
      }
      setState(() {
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
              hintText: 'Search jokes, recipes, stories…',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              description: 'Find jokes, recipes, stories, wallpapers and videos.',
            )
          : AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                final controller = _controller!;
                if (controller.status == LoadStatus.loading || controller.status == LoadStatus.idle) {
                  return const PostListShimmer();
                }
                if (controller.status == LoadStatus.error) {
                  return ErrorStateView(message: controller.error ?? 'Search failed', onRetry: controller.loadInitial);
                }
                if (controller.status == LoadStatus.empty) {
                  return const EmptyStateView(icon: Icons.search_off_rounded, title: 'No results found');
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = controller.posts[index];
                    return PostCard(
                      post: post,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PostDetailRouter(postId: post.id)),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
