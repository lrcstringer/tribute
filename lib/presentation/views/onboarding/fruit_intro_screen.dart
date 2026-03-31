import 'package:flutter/material.dart';
import '../../../domain/entities/fruit.dart';
import '../../theme/app_theme.dart';

class FruitIntroScreen extends StatefulWidget {
  final VoidCallback onNext;

  const FruitIntroScreen({super.key, required this.onNext});

  @override
  State<FruitIntroScreen> createState() => _FruitIntroScreenState();
}

class _FruitIntroScreenState extends State<FruitIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _iconFades = [];

  @override
  void initState() {
    super.initState();
    // 9 icons × 150ms apart, each fade-in 300ms → total ~1650ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
    for (int i = 0; i < FruitType.values.length; i++) {
      final start = (i * 150) / 1650;
      final end = (i * 150 + 300) / 1650;
      _iconFades.add(CurvedAnimation(
        parent: _controller,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ));
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Habits aren't the goal.",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: MyWalkColor.warmWhite,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'The goal is who you\'re becoming. In Galatians, Paul describes the fruit of a life connected to God\'s Spirit:',
            style: TextStyle(
              fontSize: 16,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // 3×3 fruit icon grid with stagger animation
          _fruitGrid(),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: MyWalkColor.golden.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                    color: MyWalkColor.golden.withValues(alpha: 0.4), width: 3),
              ),
            ),
            child: Text(
              'Your habits are how you tend the soil. The Spirit grows the fruit.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: MyWalkColor.softGold.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fruitGrid() {
    final fruits = FruitType.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 80,
      ),
      itemCount: fruits.length,
      itemBuilder: (_, i) {
        final fruit = fruits[i];
        return FadeTransition(
          opacity: _iconFades[i],
          child: Container(
            decoration: BoxDecoration(
              color: fruit.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fruit.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(fruit.icon, size: 22, color: fruit.color),
                const SizedBox(height: 6),
                Text(
                  fruit.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: fruit.color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
