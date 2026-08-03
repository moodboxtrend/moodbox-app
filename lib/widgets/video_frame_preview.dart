import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A lightweight tile that initializes a VideoPlayerController in paused state
/// at position 0 to extract and display the video scene / first frame as a thumbnail.
class VideoFramePreview extends StatefulWidget {
  final String videoUrl;
  final BorderRadius? borderRadius;

  const VideoFramePreview({
    super.key,
    required this.videoUrl,
    this.borderRadius,
  });

  @override
  State<VideoFramePreview> createState() => _VideoFramePreviewState();
}

class _VideoFramePreviewState extends State<VideoFramePreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  @override
  void didUpdateWidget(covariant VideoFramePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _initPreview();
    }
  }

  Future<void> _initPreview() async {
    if (widget.videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      await _controller!.setVolume(0.0);
      if (_controller!.value.duration.inMilliseconds > 500) {
        await _controller!.seekTo(const Duration(milliseconds: 500));
      }
      await _controller!.pause();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(18);

    if (_hasError || widget.videoUrl.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: theme.colorScheme.primary.withOpacity(0.12),
          child: Center(
            child: Icon(
              Icons.video_library_outlined,
              color: theme.colorScheme.primary.withOpacity(0.5),
              size: 40,
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: theme.colorScheme.surface,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 100,
              height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 100,
              child: VideoPlayer(_controller!),
            ),
          ),
        ],
      ),
    );
  }
}
