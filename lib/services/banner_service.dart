import '../core/network/api_client.dart';
import '../models/banner_model.dart';

class BannerService {
  final _api = ApiClient.instance;

  Future<List<BannerModel>> getBanners() async {
    final response = await _api.get('/banners');
    final data = response['data'] as List? ?? [];
    return data
        .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
