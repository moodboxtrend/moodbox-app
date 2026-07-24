import '../core/utils/safe_parse.dart';

class BannerModel {
  final String id;
  final String title;
  final String quoteText;
  final String emoji;
  final String type;
  final String bgGradientStart;
  final String bgGradientEnd;
  final String buttonText;
  final int order;

  BannerModel({
    required this.id,
    required this.title,
    required this.quoteText,
    required this.emoji,
    required this.type,
    required this.bgGradientStart,
    required this.bgGradientEnd,
    required this.buttonText,
    required this.order,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: SafeParse.string(json['_id']),
      title: SafeParse.string(json['title']),
      quoteText: SafeParse.string(json['quoteText']),
      emoji: SafeParse.string(json['emoji'], '✨'),
      type: SafeParse.string(json['type'], 'general'),
      bgGradientStart: SafeParse.string(json['bgGradientStart'], '#1B1830'),
      bgGradientEnd: SafeParse.string(json['bgGradientEnd'], '#2D2459'),
      buttonText: SafeParse.string(json['buttonText'], 'Explore'),
      order: SafeParse.intVal(json['order']),
    );
  }
}
