import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/category_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../common/no_internet_screen.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _fadeAnim;

  static const _emojis = [
    _FloatingEmoji('😂', Offset(0.10, 0.15), 28),
    _FloatingEmoji('🍲', Offset(0.82, 0.20), 24),
    _FloatingEmoji('📚', Offset(0.65, 0.70), 26),
    _FloatingEmoji('❤️', Offset(0.20, 0.75), 22),
    _FloatingEmoji('✨', Offset(0.45, 0.10), 20),
    _FloatingEmoji('😄', Offset(0.88, 0.55), 22),
    _FloatingEmoji('🌟', Offset(0.05, 0.50), 20),
    _FloatingEmoji('🎉', Offset(0.75, 0.88), 24),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final connectivity = context.read<ConnectivityProvider>();
    if (!connectivity.isOnline) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => NoInternetScreen(onRetry: _bootstrap)),
      );
      return;
    }

    await context.read<CategoryProvider>().loadCategories();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => seen ? const HomeShell() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.splashTop, AppColors.splashBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Floating emojis (background decoration) ──
            ..._emojis.map(
              (e) => _FloatingEmojiWidget(emoji: e, animation: _floatCtrl, screenSize: size),
            ),

            // ── Main centered content ──
            FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // MoodBox logo image with rounded corners & shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.40),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/images/moodbox.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, Color(0xFF9C6FFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Center(child: Text('🎁', style: TextStyle(fontSize: 48))),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // MoodBox name
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mood',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: AppColors.darkText,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'Box',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      'Fun. Food. Stories.\nAll in One Box ❤️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.darkText.withOpacity(0.55),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _FloatingEmoji {
  final String emoji;
  final Offset relativePos;
  final double size;
  const _FloatingEmoji(this.emoji, this.relativePos, this.size);
}

// ── Animated floating widget ─────────────────────────────────────────────────

class _FloatingEmojiWidget extends StatelessWidget {
  final _FloatingEmoji emoji;
  final AnimationController animation;
  final Size screenSize;

  const _FloatingEmojiWidget({
    required this.emoji,
    required this.animation,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final dy = Tween<double>(begin: -8.0, end: 8.0).evaluate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );
        return Positioned(
          left: emoji.relativePos.dx * screenSize.width,
          top: emoji.relativePos.dy * screenSize.height + dy,
          child: Opacity(
            opacity: 0.22,
            child: Text(emoji.emoji, style: TextStyle(fontSize: emoji.size)),
          ),
        );
      },
    );
  }
}
