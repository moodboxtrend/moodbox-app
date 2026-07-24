import '../core/utils/safe_parse.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String type; // joke | recipe | story | wallpaper | video | general
  final String description;
  final String icon;
  final String emoji;
  final String color;
  final String imageUrl;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.description,
    required this.icon,
    required this.emoji,
    required this.color,
    required this.imageUrl,
    required this.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: SafeParse.string(json['_id']),
      name: SafeParse.string(json['name']),
      slug: SafeParse.string(json['slug']),
      type: SafeParse.string(json['type'], 'general'),
      description: SafeParse.string(json['description']),
      icon: SafeParse.string(json['icon']),
      emoji: SafeParse.string(json['emoji'], '🎁'),
      color: SafeParse.string(json['color'], '#6D4AFF'),
      imageUrl: SafeParse.string(json['image']?['url']),
      order: SafeParse.intVal(json['order']),
    );
  }
}
