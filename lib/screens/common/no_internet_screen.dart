import 'package:flutter/material.dart';
import '../../widgets/state_placeholders.dart';

class NoInternetScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  const NoInternetScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NoInternetView(onRetry: onRetry),
      ),
    );
  }
}
