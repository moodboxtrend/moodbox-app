import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moodbox_app/core/utils/wallpaper_image_helper.dart';

void main() {
  test('creates a screen-sized cropped wallpaper file', () async {
    final tempDir = await Directory.systemTemp.createTemp('wallpaper_helper_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourcePath = '${tempDir.path}/source.jpg';
    final outputPath = '${tempDir.path}/output.jpg';

    final sourceImage = img.Image(width: 2000, height: 1000);
    img.fill(sourceImage, color: img.ColorRgb8(255, 0, 0));
    File(sourcePath).writeAsBytesSync(img.encodeJpg(sourceImage));

    await WallpaperImageHelper.createScreenSizedWallpaperFile(
      sourcePath: sourcePath,
      outputPath: outputPath,
      screenSize: const Size(1080, 1920),
    );

    final outputFile = File(outputPath);
    expect(outputFile.existsSync(), isTrue);

    final decoded = img.decodeImage(outputFile.readAsBytesSync());
    expect(decoded, isNotNull);
    expect(decoded!.width, 1080);
    expect(decoded.height, 1920);
  });
}
