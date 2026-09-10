import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// A subtle, non-intrusive floating hint that shows "Swipe up for next"
/// with a bouncing animation.
///
/// Automatically shown ONLY the first time the user opens Video or Quote reels.
/// Uses [IgnorePointer] so it never blocks touch/swipe gestures.
class SwipeHintOverlay extends StatefulWidget {
  final String? prefKey;
  final String message;

  const SwipeHintOverlay({
    super.key,
    this.prefKey,
    this.message = 'Swipe up for next',
  });

  @override
  State<SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<SwipeHintOverlay>
    with TickerProviderStateMixin {
  bool _shouldShow = false;
  bool _isVisible = false;
  late AnimationController _fadeCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _bounceAnim;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _bounceAnim = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOutCubic),
    );

    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.prefKey ?? AppConstants.prefSwipeHintSeen;
    final hasSeen = prefs.getBool(key) ?? false;

    if (!hasSeen && mounted) {
      // Mark as seen immediately so it never shows again
      await prefs.setBool(key, true);

      setState(() {
        _shouldShow = true;
        _isVisible = true;
      });

      _fadeCtrl.forward();

      // Auto-hide after 3.5 seconds
      _hideTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted && _isVisible) {
          _fadeCtrl.reverse().then((_) {
            if (mounted) {
              setState(() => _shouldShow = false);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedBuilder(
            animation: _bounceAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnim.value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.keyboard_double_arrow_up_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
