import '../core/utils/safe_parse.dart';

class IngredientModel {
  final String name;
  final String quantity;
  IngredientModel({required this.name, required this.quantity});

  factory IngredientModel.fromJson(Map<String, dynamic> json) => IngredientModel(
        name: SafeParse.string(json['name']),
        quantity: SafeParse.string(json['quantity']),
      );
}

class CookingStepModel {
  final int step;
  final String instruction;
  CookingStepModel({required this.step, required this.instruction});

  factory CookingStepModel.fromJson(Map<String, dynamic> json) => CookingStepModel(
        step: SafeParse.intVal(json['step']),
        instruction: SafeParse.string(json['instruction']),
      );
}

class RecipeDetails {
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final List<IngredientModel> ingredients;
  final List<CookingStepModel> steps;
  final String tips;
  final String? calories;
  final String? protein;
  final String? carbs;
  final String? fat;

  RecipeDetails({
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.tips,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    final nutrition = json['nutrition'] as Map<String, dynamic>? ?? {};
    return RecipeDetails(
      prepTime: SafeParse.intVal(json['prepTime']),
      cookTime: SafeParse.intVal(json['cookTime']),
      servings: SafeParse.intVal(json['servings'], 1),
      difficulty: SafeParse.string(json['difficulty'], 'Easy'),
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List? ?? [])
          .map((e) => CookingStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: SafeParse.string(json['tips']),
      calories: nutrition['calories']?.toString(),
      protein: nutrition['protein']?.toString(),
      carbs: nutrition['carbs']?.toString(),
      fat: nutrition['fat']?.toString(),
    );
  }
}

class StoryDetails {
  final int readingTime;
  final String? storyType;
  final String ageRating;

  StoryDetails({required this.readingTime, this.storyType, required this.ageRating});

  factory StoryDetails.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return StoryDetails(
      readingTime: SafeParse.intVal(json['readingTime']),
      storyType: json['storyType'],
      ageRating: SafeParse.string(json['ageRating'], 'All Ages'),
    );
  }
}

class JokeDetails {
  final String? language;
  JokeDetails({this.language});

  factory JokeDetails.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return JokeDetails(language: json['language']);
  }
}

class WallpaperDetails {
  final String resolution;
  final String orientation;
  WallpaperDetails({required this.resolution, required this.orientation});

  factory WallpaperDetails.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return WallpaperDetails(
      resolution: SafeParse.string(json['resolution']),
      orientation: SafeParse.string(json['orientation'], 'Portrait'),
    );
  }
}

class VideoDetails {
  final String videoUrl;
  final String source; // YouTube | Direct Upload | Vimeo | Other Link
  final int duration;
  VideoDetails({required this.videoUrl, required this.source, required this.duration});

  factory VideoDetails.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return VideoDetails(
      videoUrl: SafeParse.string(json['videoUrl']),
      source: SafeParse.string(json['source'], 'YouTube'),
      duration: SafeParse.intVal(json['duration']),
    );
  }
}

class PostModel {
  final String id;
  final String title;
  final String slug;
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final String contentType;
  final String shortDescription;
  final String content;
  final String featuredImageUrl;
  final List<String> tags;
  final DateTime? publishDate;
  final bool isFeatured;
  final bool isTrending;
  final bool allowSave;
  final bool allowShare;
  final int views;

  final RecipeDetails? recipeDetails;
  final StoryDetails? storyDetails;
  final JokeDetails? jokeDetails;
  final WallpaperDetails? wallpaperDetails;
  final VideoDetails? videoDetails;

  PostModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.contentType,
    required this.shortDescription,
    required this.content,
    required this.featuredImageUrl,
    required this.tags,
    required this.publishDate,
    required this.isFeatured,
    required this.isTrending,
    required this.allowSave,
    required this.allowShare,
    required this.views,
    this.recipeDetails,
    this.storyDetails,
    this.jokeDetails,
    this.wallpaperDetails,
    this.videoDetails,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final subcategory = json['subcategory'];
    final contentType = SafeParse.string(json['contentType'], 'general');

    return PostModel(
      id: SafeParse.string(json['_id']),
      title: SafeParse.string(json['title']),
      slug: SafeParse.string(json['slug']),
      categoryId: category is Map ? SafeParse.string(category['_id']) : SafeParse.string(category),
      categoryName: category is Map ? SafeParse.string(category['name']) : '',
      subcategoryId: subcategory is Map ? SafeParse.string(subcategory['_id']) : SafeParse.string(subcategory),
      subcategoryName: subcategory is Map ? SafeParse.string(subcategory['name']) : '',
      contentType: contentType,
      shortDescription: SafeParse.string(json['shortDescription']),
      content: SafeParse.string(json['content']),
      featuredImageUrl: SafeParse.string(json['featuredImage']?['url']),
      tags: SafeParse.stringList(json['tags']),
      publishDate: SafeParse.dateVal(json['publishDate']),
      isFeatured: SafeParse.boolVal(json['isFeatured']),
      isTrending: SafeParse.boolVal(json['isTrending']),
      allowSave: SafeParse.boolVal(json['allowSave'], true),
      allowShare: SafeParse.boolVal(json['allowShare'], true),
      views: SafeParse.intVal(json['views']),
      recipeDetails: contentType == 'recipe' ? RecipeDetails.fromJson(json['recipeDetails']) : null,
      storyDetails: contentType == 'story' ? StoryDetails.fromJson(json['storyDetails']) : null,
      jokeDetails: contentType == 'joke' ? JokeDetails.fromJson(json['jokeDetails']) : null,
      wallpaperDetails: contentType == 'wallpaper' ? WallpaperDetails.fromJson(json['wallpaperDetails']) : null,
      videoDetails: contentType == 'video' ? VideoDetails.fromJson(json['videoDetails']) : null,
    );
  }

  /// Returns explicit featuredImageUrl if non-empty, or auto-extracted thumbnail (YouTube / Cloudinary) for video posts.
  String get resolvedThumbnailUrl {
    if (featuredImageUrl.isNotEmpty) return featuredImageUrl;
    if (videoDetails != null && videoDetails!.videoUrl.isNotEmpty) {
      final url = videoDetails!.videoUrl;
      final ytId = extractYoutubeId(url);
      if (ytId != null && ytId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
      }
      final cloudThumb = extractCloudinaryVideoThumbnail(url);
      if (cloudThumb != null && cloudThumb.isNotEmpty) {
        return cloudThumb;
      }
    }
    return '';
  }

  static String? extractYoutubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|shorts\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final id = match.group(2);
      if (id != null && id.length == 11) return id;
    }
    return null;
  }

  static String? extractCloudinaryVideoThumbnail(String url) {
    if (url.isEmpty) return null;
    if (url.contains('res.cloudinary.com') &&
        (url.contains('/video/upload/') ||
            url.endsWith('.mp4') ||
            url.endsWith('.mov') ||
            url.endsWith('.webm'))) {
      var imgUrl = url.replaceAll(
          RegExp(r'\.(mp4|mov|webm|avi|mkv)$', caseSensitive: false), '.jpg');
      if (imgUrl.contains('/video/upload/') && !imgUrl.contains('/so_')) {
        imgUrl = imgUrl.replaceFirst('/video/upload/', '/video/upload/so_1.0/');
      }
      return imgUrl;
    }
    return null;
  }
}

