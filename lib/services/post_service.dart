import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/paginated_response.dart';
import '../models/post_model.dart';

class PostService {
  final _api = ApiClient.instance;

  Future<PaginatedResponse<PostModel>> getPosts({
    String? categoryId,
    String? subcategoryId,
    String? contentType,
    String? search,
    bool? isFeatured,
    bool? isTrending,
    List<String>? ids,
    int page = 1,
    int limit = 20,
    String sortBy = 'publishDate',
    String order = 'desc',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'order': order,
    };
    if (categoryId != null) query['category'] = categoryId;
    if (subcategoryId != null) query['subcategory'] = subcategoryId;
    if (contentType != null) query['contentType'] = contentType;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (isFeatured != null) query['isFeatured'] = isFeatured.toString();
    if (isTrending != null) query['isTrending'] = isTrending.toString();
    if (ids != null && ids.isNotEmpty) query['ids'] = ids.join(',');

    final json = await _api.get(ApiConstants.posts, queryParameters: query);
    return PaginatedResponse.fromJson(json, PostModel.fromJson);
  }

  Future<PostModel> getPostById(String idOrSlug) async {
    final json = await _api.get(ApiConstants.postById(idOrSlug));
    return PostModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Fire-and-forget analytics ping - failures are ignored on purpose so the
  /// user's save/share action never feels blocked by network issues.
  Future<void> trackAction(String postId, String action) async {
    try {
      await _api.post(ApiConstants.trackPost(postId), data: {'action': action});
    } catch (_) {
      // ignore
    }
  }
}
