import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/share_helper.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/state_placeholders.dart';

/// Full-screen vertical scroll image viewer for quotes / motivational images.
/// - Image is shown at its original aspect ratio (BoxFit.contain).
/// - No text overlay — pure clean image view.
/// - Right sidebar: Save (bookmark), Share, Download.
/// - Swipe up/down to go to next/previous image.
class QuoteReelsScreen extends StatefulWidget {
  final String? initialPostId;
  final List<PostModel>? posts;

  const QuoteReelsScreen({
    super.key,
    this.initialPostId,
    this.posts,
  });

  @override
  State<QuoteReelsScreen> createState() => _QuoteReelsScreenState();
}

class _QuoteReelsScreenState extends State<QuoteReelsScreen> {
  final _postService = PostService();
  final PageController _pageController = PageController();

  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (widget.posts != null && widget.posts!.isNotEmpty) {
      _posts = widget.posts!;
      _setInitialIndex();
      setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await _postService.getPosts(limit: 50);
      if (mounted) {
        setState(() {
          _posts = res.items
              .where((p) => p.featuredImageUrl.isNotEmpty)
              .toList();
          _isLoading = false;
        });
        _setInitialIndex();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setInitialIndex() {
    if (widget.initialPostId != null && _posts.isNotEmpty) {
      final idx = _posts.indexWhere((p) => p.id == widget.initialPostId);
      if (idx != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(idx);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: const EmptyStateView(
          icon: Icons.image_outlined,
          title: 'No Images Yet',
          description: 'Check back soon!',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _posts.length,
        itemBuilder: (context, index) => _QuoteItem(post: _posts[index]),
      ),
    );
  }
}

// ── Single Image Page ─────────────────────────────────────────────────────────

class _QuoteItem extends StatefulWidget {
  final PostModel post;
  const _QuoteItem({required this.post});

  @override
  State<_QuoteItem> createState() => _QuoteItemState();
}

class _QuoteItemState extends State<_QuoteItem> {
  bool _isDownloading = false;

  Future<void> _download() async {
    final url = widget.post.featuredImageUrl;
    if (url.isEmpty) return;
    setState(() => _isDownloading = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission denied.')),
            );
          }
          return;
        }
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/moodbox_quote_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(url, path);
      await Gal.putImage(path, album: 'MoodBox');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery 🖼️')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Stack(
      children: [
        // ── Pure black background ─────────────────────────────────────────
        const Positioned.fill(child: ColoredBox(color: Colors.black)),

        // ── Image: full original aspect ratio, centered, no cut/stretch ──
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                post.featuredImageUrl,
                // contain = shows the entire image without any crop or stretch
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: Colors.white38, size: 56),
                      SizedBox(height: 8),
                      Text('Failed to load',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Top gradient + Back button ────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 6,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        // ── Right sidebar: Save, Share, Download ─────────────────────────
        Positioned(
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bookmark / Save
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: FavoriteButton(
                  postId: post.id,
                  allowSave: post.allowSave,
                ),
              ),
              const SizedBox(height: 16),

              // Share
              if (post.allowShare) ...[
                _ActionButton(
                  icon: Icons.share_outlined,
                  onTap: () => ShareHelper.sharePost(post),
                ),
                const SizedBox(height: 16),
              ],

              // Download
              _ActionButton(
                icon: _isDownloading ? null : Icons.download_rounded,
                isLoading: _isDownloading,
                onTap: _isDownloading ? null : _download,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable sidebar action button ───────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
