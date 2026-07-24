import '../core/utils/safe_parse.dart';

class AppSettingsModel {
  final String websiteName;
  final String logoUrl;
  final String facebook;
  final String instagram;
  final String twitter;
  final String youtube;
  final String whatsapp;

  AppSettingsModel({
    required this.websiteName,
    required this.logoUrl,
    required this.facebook,
    required this.instagram,
    required this.twitter,
    required this.youtube,
    required this.whatsapp,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final social = json['social'] as Map<String, dynamic>? ?? {};
    return AppSettingsModel(
      websiteName: SafeParse.string(json['websiteName'], 'MoodBox'),
      logoUrl: SafeParse.string(json['logo']?['url']),
      facebook: SafeParse.string(social['facebook']),
      instagram: SafeParse.string(social['instagram']),
      twitter: SafeParse.string(social['twitter']),
      youtube: SafeParse.string(social['youtube']),
      whatsapp: SafeParse.string(social['whatsapp']),
    );
  }

  factory AppSettingsModel.empty() => AppSettingsModel(
        websiteName: 'MoodBox',
        logoUrl: '',
        facebook: '',
        instagram: '',
        twitter: '',
        youtube: '',
        whatsapp: '',
      );
}
