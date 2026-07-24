import '../core/utils/safe_parse.dart';

class SubcategoryModel {
  final String id;
  final String name;
  final String slug;
  final String categoryId;
  final int order;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.order,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final categoryId = category is Map ? SafeParse.string(category['_id']) : SafeParse.string(category);

    return SubcategoryModel(
      id: SafeParse.string(json['_id']),
      name: SafeParse.string(json['name']),
      slug: SafeParse.string(json['slug']),
      categoryId: categoryId,
      order: SafeParse.intVal(json['order']),
    );
  }
}
