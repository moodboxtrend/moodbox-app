import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';

class CategoryService {
  final _api = ApiClient.instance;

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final json = await _api.get(
      ApiConstants.categories,
      queryParameters: type != null ? {'type': type} : null,
    );
    final list = json['data'] as List? ?? [];
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SubcategoryModel>> getSubcategories({String? categoryId}) async {
    final json = await _api.get(
      ApiConstants.subcategories,
      queryParameters: categoryId != null ? {'category': categoryId} : null,
    );
    final list = json['data'] as List? ?? [];
    return list.map((e) => SubcategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
