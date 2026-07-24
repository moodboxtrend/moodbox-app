/// Static app metadata + content-type keys shared across the app.
/// Keep these in sync with the admin panel's backend/config/constants.js.
class AppConstants {
  AppConstants._();

  static const String appName = 'MoodBox';

  static const String typeJoke = 'joke';
  static const String typeRecipe = 'recipe';
  static const String typeStory = 'story';
  static const String typeWallpaper = 'wallpaper';
  static const String typeVideo = 'video';
  static const String typeGeneral = 'general';

  static const List<String> allContentTypes = [
    typeJoke, typeRecipe, typeStory, typeWallpaper, typeVideo,
  ];

  // SharedPreferences keys
  static const String prefFavorites = 'favorite_post_ids';
  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboardingSeen = 'onboarding_seen';

  // TODO: set this to your actual hosted privacy policy before publishing.
  static const String privacyPolicyUrl = 'https://your-domain.com/privacy-policy';
  static const String termsUrl = 'https://your-domain.com/terms';
}
