import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/share_helper.dart';
import '../../core/utils/wallpaper_image_helper.dart';
import '../../models/post_model.dart';
import '../../widgets/favorite_button.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final PostModel post;
  const WallpaperDetailScreen({super.key, required this.post});

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _isBusy = false;

  Future<String> _downloadToTempFile() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/moodbox_${widget.post.id}.jpg';
    await Dio().download(widget.post.featuredImageUrl, path);
    return path;
  }

  Future<void> _saveToGallery() async {
    if (widget.post.featuredImageUrl.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          _showSnack(
              'Permission denied. Enable photo access in Settings to save wallpapers.');
          return;
        }
      }
      final path = await _downloadToTempFile();
      await Gal.putImage(path, album: 'MoodBox');
      _showSnack('Saved to your gallery');
    } catch (e) {
      _showSnack('Failed to save image. Please try again.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _setAsWallpaper(WallpaperTarget wallpaperTarget) async {
    if (widget.post.featuredImageUrl.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final sourcePath = '${tempDir.path}/moodbox_${widget.post.id}_source.jpg';
      final outputPath = '${tempDir.path}/moodbox_${widget.post.id}_wallpaper.jpg';

      await Dio().download(widget.post.featuredImageUrl, sourcePath);
      final screenSize = MediaQuery.of(context).size;
      await WallpaperImageHelper.createScreenSizedWallpaperFile(
        sourcePath: sourcePath,
        outputPath: outputPath,
        screenSize: screenSize,
      );

      final WallpaperResult result = await AsyncWallpaper.setWallpaper(
        WallpaperRequest(
          target: wallpaperTarget,
          sourceType: WallpaperSourceType.file,
          source: outputPath,
          goToHome: true,
        ),
      );

      if (result.isSuccess) {
        _showSnack('Wallpaper applied');
      } else {
        _showSnack(result.error?.message ?? 'Could not set wallpaper on this device.');
      }
    } catch (e) {
      _showSnack('Could not set wallpaper on this device.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showWallpaperOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.45;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Home screen'),
                    onTap: () {
                      Navigator.pop(context);
                      _setAsWallpaper(WallpaperTarget.home);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Lock screen'),
                    onTap: () {
                      Navigator.pop(context);
                      _setAsWallpaper(WallpaperTarget.lock);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.smartphone_outlined),
                    title: const Text('Both'),
                    onTap: () {
                      Navigator.pop(context);
                      _setAsWallpaper(WallpaperTarget.both);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: 56,
        actions: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, maxWidth: 56),
            child: FavoriteButton(postId: post.id, allowSave: post.allowSave),
          ),
          if (post.allowShare)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, maxWidth: 56),
              child: IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => ShareHelper.sharePost(post)),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;

            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: SizedBox(
                      width: viewportWidth,
                      height: viewportHeight,
                      child: post.featuredImageUrl.isNotEmpty
                          ? ClipRect(
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black,
                                child: Image.network(
                                  post.featuredImageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(Icons.broken_image_outlined,
                                            color: Colors.white38, size: 64),
                                      ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined,
                                  color: Colors.white38, size: 64)),
                    ),
                  ),
                ),
                if (_isBusy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black45,
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Download Icon Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isBusy ? null : _saveToGallery,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: Colors.white38, width: 1.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.download_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Set Wallpaper Icon Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isBusy ? null : _showWallpaperOptions,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.5),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.wallpaper_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
