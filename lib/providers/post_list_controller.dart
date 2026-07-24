import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

enum LoadStatus { idle, loading, loadingMore, success, error, empty }

/// Generic infinite-scroll controller for any filtered post list: a category
/// feed, a subcategory feed, search results, trending, etc. Create a fresh
/// instance per screen via ChangeNotifierProvider so filters don't leak
/// between screens.
class PostListController extends ChangeNotifier {
  final PostService _service = PostService();

  final String? categoryId;
  final String? subcategoryId;
  final String? contentType;
  final String? search;
  final bool? isFeatured;
  final bool? isTrending;

  PostListController({
    this.categoryId,
    this.subcategoryId,
    this.contentType,
    this.search,
    this.isFeatured,
    this.isTrending,
  });

  final List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  LoadStatus _status = LoadStatus.idle;
  LoadStatus get status => _status;

  String? _error;
  String? get error => _error;

  int _page = 1;
  bool _hasNextPage = true;

  Future<void> loadInitial() async {
    _status = LoadStatus.loading;
    _page = 1;
    notifyListeners();
    await _fetch(reset: true);
  }

  Future<void> refresh() async {
    _page = 1;
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (_status == LoadStatus.loadingMore || !_hasNextPage) return;
    _status = LoadStatus.loadingMore;
    notifyListeners();
    _page += 1;
    await _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset}) async {
    try {
      final result = await _service.getPosts(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        contentType: contentType,
        search: search,
        isFeatured: isFeatured,
        isTrending: isTrending,
        page: _page,
      );

      if (reset) _posts.clear();
      _posts.addAll(result.items);
      _hasNextPage = result.meta.hasNextPage;
      _status = _posts.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
