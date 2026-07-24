/// Central place for API base URL and endpoint paths.
/// IMPORTANT: change [baseUrl] to your deployed backend URL before release.
/// Never point a production release build at localhost.
class ApiConstants {
  ApiConstants._();

  // TODO: replace with your deployed backend, e.g. https://api.moodbox.com/api/public
  static const String baseUrl = 'https://moodbox-backend.onrender.com/api/public';

  static const String categories = '/categories';
  static const String subcategories = '/subcategories';
  static const String posts = '/posts';
  static const String settings = '/settings';

  static String postById(String idOrSlug) => '/posts/$idOrSlug';
  static String trackPost(String id) => '/posts/$id/track';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
