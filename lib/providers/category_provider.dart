import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

enum LoadStatus { idle, loading, success, error }

/// Loaded once at app start and shared across Home/Categories screens so we
/// don't refetch the (rarely-changing) category list on every navigation.
class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<CategoryModel> _categories = [];
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  List<CategoryModel> get categories => _categories;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> loadCategories({bool force = false}) async {
    if (_status == LoadStatus.success && !force) return;

    _status = LoadStatus.loading;
    notifyListeners();

    try {
      _categories = await _service.getCategories();
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  CategoryModel? byId(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
