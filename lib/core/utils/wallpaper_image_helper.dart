import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

class WallpaperImageHelper {
  static Future<void> createScreenSizedWallpaperFile({
    required String sourcePath,
    required String outputPath,
    required Size screenSize,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw FileSystemException('Source wallpaper file does not exist', sourcePath);
    }

    final sourceBytes = await sourceFile.readAsBytes();
    final decodedImage = img.decodeImage(sourceBytes);
    if (decodedImage == null) {
      throw Exception('Unable to decode wallpaper image');
    }

    final targetWidth = screenSize.width.round();
    final targetHeight = screenSize.height.round();

    final sourceWidth = decodedImage.width;
    final sourceHeight = decodedImage.height;
    final screenAspectRatio = targetWidth / targetHeight;
    final imageAspectRatio = sourceWidth / sourceHeight;

    int resizedWidth;
    int resizedHeight;

    if (imageAspectRatio > screenAspectRatio) {
      resizedHeight = targetHeight;
      resizedWidth = (targetHeight * imageAspectRatio).round();
    } else {
      resizedWidth = targetWidth;
      resizedHeight = (targetWidth / imageAspectRatio).round();
    }

    final resized = img.copyResize(
      decodedImage,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.cubic,
    );

    final offsetX = ((resizedWidth - targetWidth) / 2).round();
    final offsetY = ((resizedHeight - targetHeight) / 2).round();

    final cropped = img.copyCrop(
      resized,
      x: offsetX,
      y: offsetY,
      width: targetWidth,
      height: targetHeight,
    );

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(cropped));
  }
}
