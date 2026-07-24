import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/share_helper.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/state_placeholders.dart';

/// Full-screen Instagram Reels style vertical video player.
class VideoReelsScreen extends StatefulWidget {
  final String? initialPostId;
  final List<PostModel>? posts;

  const VideoReelsScreen({
    super.key,
    this.initialPostId,
    this.posts,
  });

  @override
  State<VideoReelsScreen> createState() => _VideoReelsScreenState();
}

class _VideoReelsScreenState extends State<VideoReelsScreen> {
  final _postService = PostService();
  final PageController _pageController = PageController();

  List<PostModel> _videoPosts = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (widget.posts != null && widget.posts!.isNotEmpty) {
      _videoPosts = widget.posts!;
      _setInitialIndex();
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _postService.getPosts(contentType: 'video', limit: 50);
      if (mounted) {
        setState(() {
          _videoPosts = res.items;
          _isLoading = false;
        });
        _setInitialIndex();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setInitialIndex() {
    if (widget.initialPostId != null && _videoPosts.isNotEmpty) {
      final idx = _videoPosts.indexWhere((p) => p.id == widget.initialPostId);
      if (idx != -1) {
        _currentIndex = idx;
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

    if (_videoPosts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
        body: const EmptyStateView(
          icon: Icons.play_circle_outline,
          title: 'No Videos Yet',
          description: 'Check back soon for new reels!',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videoPosts.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final post = _videoPosts[index];
          final isCurrent = index == _currentIndex;
          return _ReelItem(post: post, isActive: isCurrent);
        },
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final PostModel post;
  final bool isActive;

  const _ReelItem({required this.post, required this.isActive});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller?.play();
        setState(() => _isPlaying = true);
      } else {
        _controller?.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _initVideo() async {
    final url = widget.post.videoDetails?.videoUrl ?? '';
    if (url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.isActive) {
          _controller!.play();
          setState(() => _isPlaying = true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _downloadVideo() async {
    final videoUrl = widget.post.videoDetails?.videoUrl ?? '';
    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL not available.')),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission denied to save video.')),
            );
          }
          return;
        }
      }

      final dir = await getTemporaryDirectory();
      final savePath =
          '${dir.path}/moodbox_video_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await Dio().download(videoUrl, savePath);
      await Gal.putVideo(savePath, album: 'MoodBox');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video downloaded to your gallery! 🎬')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download video. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Stack(
      children: [
        // ── Video Background ────────────────────────────────────────────────
        GestureDetector(
          onTap: _togglePlay,
          child: Positioned.fill(
            child: _hasError
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white70, size: 48),
                        SizedBox(height: 8),
                        Text('Failed to load video', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : _isInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          if (post.featuredImageUrl.isNotEmpty)
                            Positioned.fill(
                              child: Image.network(post.featuredImageUrl, fit: BoxFit.cover),
                            ),
                          const CircularProgressIndicator(color: Colors.white),
                        ],
                      ),
          ),
        ),

        // ── Play / Pause Overlay Icon when tapped ─────────────────────────
        if (_isInitialized && !_isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
            ),
          ),

        // ── Back Button Top Left ──────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        // ── Right Action Sidebar (Save, Share, Download) ───────────────────
        Positioned(
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Save / Bookmark button
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: FavoriteButton(postId: post.id, allowSave: post.allowSave),
              ),
              const SizedBox(height: 18),

              // Share button
              if (post.allowShare)
                GestureDetector(
                  onTap: () => ShareHelper.sharePost(post),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_outlined, color: Colors.white, size: 24),
                  ),
                ),

              if (post.allowShare) const SizedBox(height: 18),

              // Download button
              GestureDetector(
                onTap: _isDownloading ? null : _downloadVideo,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Content Overlay (Title, Subcategory, Views) ────────────
        Positioned(
          left: 16,
          right: 70,
          bottom: MediaQuery.of(context).padding.bottom + 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (post.subcategoryName.isNotEmpty || post.categoryName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.subcategoryName.isNotEmpty ? post.subcategoryName : post.categoryName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
              if (post.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
