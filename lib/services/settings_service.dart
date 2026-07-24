import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/app_settings_model.dart';

class SettingsService {
  final _api = ApiClient.instance;

  Future<AppSettingsModel> getSettings() async {
    final json = await _api.get(ApiConstants.settings);
    final data = json['data'];
    if (data == null || data is! Map<String, dynamic> || data.isEmpty) {
      return AppSettingsModel.empty();
    }
    return AppSettingsModel.fromJson(data);
  }
}
