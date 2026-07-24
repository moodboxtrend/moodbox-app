import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a direct video file URL (Direct Upload / Vimeo direct link / Other).
class DirectVideoPlayer extends StatefulWidget {
  final String url;
  const DirectVideoPlayer({super.key, required this.url});

  @override
  State<DirectVideoPlayer> createState() => _DirectVideoPlayerState();
}

class _DirectVideoPlayerState extends State<DirectVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController.value.aspectRatio,
        );
      });
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.error_outline, size: 40)),
      );
    }
    if (_chewieController == null) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Chewie(controller: _chewieController!);
  }
}
