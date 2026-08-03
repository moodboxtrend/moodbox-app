import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../models/app_settings_model.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  AppSettingsModel? _settings;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    AppSettingsModel settings;
    try {
      settings = await _settingsService.getSettings();
    } catch (_) {
      settings = AppSettingsModel.empty();
    }
    if (mounted) {
      setState(() {
        _packageInfo = info;
        _settings = settings;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const _SectionLabel('Connect with us'),
          if (settings != null) ...[
            if (settings.facebook.isNotEmpty)
              ListTile(leading: const Icon(Icons.facebook), title: const Text('Facebook'), onTap: () => _openUrl(settings.facebook)),
            if (settings.instagram.isNotEmpty)
              ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Instagram'), onTap: () => _openUrl(settings.instagram)),
            if (settings.twitter.isNotEmpty)
              ListTile(leading: const Icon(Icons.alternate_email_rounded), title: const Text('Twitter / X'), onTap: () => _openUrl(settings.twitter)),
            if (settings.youtube.isNotEmpty)
              ListTile(leading: const Icon(Icons.play_circle_outline_rounded), title: const Text('YouTube'), onTap: () => _openUrl(settings.youtube)),
            if (settings.whatsapp.isNotEmpty)
              ListTile(leading: const Icon(Icons.chat_bubble_outline_rounded), title: const Text('WhatsApp'), onTap: () => _openUrl(settings.whatsapp)),
          ],

          const Divider(),
          const _SectionLabel('About'),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share this app'),
            onTap: () {
              Share.share(
                'Install ${AppConstants.appName} to get jokes, recipes, stories, wallpapers, and videos in one app.\n\n${AppConstants.playStoreUrl}',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _openUrl(AppConstants.termsUrl),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('App version'),
            trailing: Text(_packageInfo?.version ?? '—'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
