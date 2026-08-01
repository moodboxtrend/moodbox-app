import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbox_app/models/post_model.dart';
import 'package:moodbox_app/providers/favorites_provider.dart';
import 'package:moodbox_app/screens/wallpaper/wallpaper_detail_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('wallpaper detail screen uses a responsive layout for small screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final post = PostModel(
      id: '1',
      title: 'Wallpaper',
      slug: 'wallpaper',
      categoryId: '1',
      categoryName: 'Wallpaper',
      subcategoryId: '1',
      subcategoryName: 'Wallpaper',
      contentType: 'wallpaper',
      shortDescription: '',
      content: '',
      featuredImageUrl: '',
      tags: const <String>[],
      publishDate: null,
      isFeatured: false,
      isTrending: false,
      allowSave: true,
      allowShare: true,
      views: 0,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FavoritesProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: WallpaperDetailScreen(post: post),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LayoutBuilder), findsWidgets);
    expect(find.byType(WallpaperDetailScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
