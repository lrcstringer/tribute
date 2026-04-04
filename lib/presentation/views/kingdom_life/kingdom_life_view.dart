import 'package:flutter/material.dart';
import '../fruit/fruit_portfolio_view.dart';
import '../kingdom_life/beatitudes_view.dart';
import '../../theme/app_theme.dart';

class KingdomLifeView extends StatelessWidget {
  const KingdomLifeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kingdom Life',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Grow in character. Live the kingdom way.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _KingdomCard(
                      icon: Icons.eco,
                      title: 'Fruit of\nthe Spirit',
                      subtitle: 'Galatians 5:22-23',
                      colour: const Color(0xFF66CDAA),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FruitPortfolioView(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KingdomCard(
                      icon: Icons.self_improvement,
                      title: 'The\nBeatitudes',
                      subtitle: 'Matthew 5:3-12',
                      colour: MyWalkColor.golden,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BeatitudesView(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KingdomCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color colour;
  final VoidCallback onTap;

  const _KingdomCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colour.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: colour),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: colour.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
