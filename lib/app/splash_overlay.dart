import 'dart:async';

import 'package:flutter/material.dart';

/// Splash mostrata dentro l'app per [duration] dopo l'avvio, poi sfuma
/// rivelando [child]. Riprende l'immagine della launch screen nativa, così il
/// passaggio dalla splash di sistema a quella Flutter non si nota (su Android
/// 12+ il sistema mostra solo il logo: qui compare l'immagine completa).
/// Un tocco la chiude subito.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  static const image = AssetImage('assets/branding/splash.jpg');
  static const background = Color(0xFF03011A);
  static const fadeDuration = Duration(milliseconds: 400);

  final Widget child;
  final Duration duration;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: SplashOverlay.fadeDuration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
  Timer? _timer;
  bool _visible = true;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(SplashOverlay.image, context);
    }
  }

  void _dismiss() {
    _timer?.cancel();
    if (_fade.isAnimating || !_visible) {
      return;
    }
    _fade.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return widget.child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: ReverseAnimation(_fade),
          child: GestureDetector(
            key: const ValueKey('splash'),
            onTap: _dismiss,
            child: const ColoredBox(
              color: SplashOverlay.background,
              child: Image(
                image: SplashOverlay.image,
                fit: BoxFit.cover,
                semanticLabel: 'Intonia',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
