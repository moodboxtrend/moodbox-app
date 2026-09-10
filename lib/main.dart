import 'package:flutter/material.dart';
import 'app.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  runApp(const MoodBoxApp());
}
