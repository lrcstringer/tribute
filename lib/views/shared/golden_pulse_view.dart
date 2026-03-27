import 'package:flutter/material.dart';

class GoldenPulseView extends StatefulWidget {
  final VoidCallback? onComplete;

  const GoldenPulseView({super.key, this.onComplete});

  @override
  State<GoldenPulseView> createState() => _GoldenPulseViewState();
}

class _GoldenPulseViewState extends State<GoldenPulseView>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _checkController;

  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _ring3Scale;
  late final Animation<double> _ring3Opacity;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _ring1Scale = Tween(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _ringController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _ring1Opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _ring2Scale = Tween(begin: 0.5, end: 1.8).animate(
      CurvedAnimation(parent: _ringController, curve: const Interval(0.1, 0.75, curve: Curves.easeOut)),
    );
    _ring2Opacity = Tween(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: const Interval(0.1, 0.75, curve: Curves.easeIn)),
    );
    _ring3Scale = Tween(begin: 0.5, end: 2.2).animate(
      CurvedAnimation(parent: _ringController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _ring3Opacity = Tween(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: const Interval(0.2, 1.0, curve: Curves.easeIn)),
    );
    _checkScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: const Interval(0.0, 0.3)),
    );

    _start();
  }

  void _start() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    _ringController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _checkController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const golden = Color(0xFFD4A843);
    const size = 72.0;

    return SizedBox(
      width: size * 2.5,
      height: size * 2.5,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ringController, _checkController]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(size, _ring3Scale.value, _ring3Opacity.value, golden.withValues(alpha: 0.3)),
              _buildRing(size, _ring2Scale.value, _ring2Opacity.value, golden.withValues(alpha: 0.5)),
              _buildRing(size, _ring1Scale.value, _ring1Opacity.value, golden.withValues(alpha: 0.7)),
              Transform.scale(
                scale: _checkScale.value,
                child: Opacity(
                  opacity: _checkOpacity.value.clamp(0.0, 1.0),
                  child: Container(
                    width: size * 0.65,
                    height: size * 0.65,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [golden, Color(0xFFB8891E)],
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRing(double baseSize, double scale, double opacity, Color color) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
              stops: const [0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
