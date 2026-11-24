import 'package:material_ui/material_ui.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lottie/lottie.dart';

/// Seamless animated splash screen that hands off from `flutter_native_splash`
/// using the same background color, logo, and branding, layered with a Lottie
/// animation before cross-fading into [child].
class LottieSplashScreen extends StatefulWidget {
  const LottieSplashScreen({super.key, required this.child});

  /// The destination widget displayed after the splash animation finishes.
  final Widget child;

  /// Matches `color` in `flutter_native_splash.yaml` for a flicker-free handoff.
  static const Color splashBackgroundColor = Color(0xFF10131A);
  static const String lottieAssetPath = 'assets/animations/sport_ball.json';

  @override
  State<LottieSplashScreen> createState() => _LottieSplashScreenState();
}

class _LottieSplashScreenState extends State<LottieSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;
  bool _nativeSplashRemoved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener(_onAnimationStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeNativeSplash();
      if (!_controller.isAnimating && !_completed && mounted) {
        _controller.forward();
      }
    });
  }

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    try {
      FlutterNativeSplash.remove();
    } catch (_) {
      // Safe no-op in test environments without native splash channels.
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_completed) {
      setState(() {
        _completed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _completed
          ? KeyedSubtree(
              key: const ValueKey('splash_child'),
              child: widget.child,
            )
          : Scaffold(
              key: const ValueKey('lottie_splash'),
              backgroundColor: LottieSplashScreen.splashBackgroundColor,
              body: SafeArea(
                child: Column(
                  children: [
                    const Spacer(),
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Lottie.asset(
                              LottieSplashScreen.lottieAssetPath,
                              controller: _controller,
                              width: 240,
                              height: 240,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _controller.duration = composition.duration;
                                if (!_completed && mounted) {
                                  _controller.forward(from: _controller.value);
                                }
                              },
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Image.asset(
                        'assets/images/branding/branding_1.png',
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
