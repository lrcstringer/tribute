import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../theme/app_theme.dart';
import 'fruit_detail_view.dart';
import 'fruit_library_view.dart';

class FruitPortfolioView extends StatelessWidget {
  const FruitPortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FruitPortfolioProvider>();
    final portfolio = provider.portfolio;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            floating: true,
            title: const Text(
              'The Fruit Growing in You',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite),
            ),
            centerTitle: false,
          ),
          if (provider.isLoading && portfolio == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: MyWalkColor.golden)),
            )
          else if (portfolio == null)
            const SliverFillRemaining(child: Center(child: _EmptyState()))
          else ...[
            // Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u201cBut the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.\u201d',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u2014 Galatians 5:22\u201323',
                      style: TextStyle(
                        fontSize: 12,
                        color: MyWalkColor.softGold.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your habits and practices prepare the ground for the on-going work of the Lord in your life.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3×3 Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 100,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final fruit = FruitType.values[i];
                    final entry = portfolio.entryFor(fruit);
                    return _FruitTile(
                      fruit: fruit,
                      entry: entry,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FruitDetailView(fruit: fruit)),
                      ),
                    );
                  },
                  childCount: FruitType.values.length,
                ),
              ),
            ),

            // Weekly summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _WeeklySummary(portfolio: portfolio),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ],
      ),
    );
  }
}

// ── Fruit Tile ─────────────────────────────────────────────────────────────────

class _FruitTile extends StatelessWidget {
  final FruitType fruit;
  final FruitPortfolioEntry entry;
  final VoidCallback onTap;

  const _FruitTile({
    required this.fruit,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = entry.habitCount > 0 && entry.weeklyCompletions > 0;
    final isDormant = entry.habitCount > 0 && entry.weeklyCompletions == 0;

    Color bgColor;
    BoxBorder border;
    double iconOpacity;

    if (isActive) {
      bgColor = fruit.color.withValues(alpha: 0.18);
      border = Border.all(color: fruit.color, width: 1.5);
      iconOpacity = 1.0;
    } else if (isDormant) {
      bgColor = fruit.color.withValues(alpha: 0.10);
      border = Border.all(color: fruit.color.withValues(alpha: 0.6));
      iconOpacity = 0.75;
    } else {
      bgColor = fruit.color.withValues(alpha: 0.06);
      border = Border.all(color: fruit.color.withValues(alpha: 0.45));
      iconOpacity = 0.55;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: iconOpacity,
              child: Icon(fruit.icon, size: 24, color: fruit.color),
            ),
            const SizedBox(height: 6),
            Text(
              fruit.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: fruit.color.withValues(alpha: iconOpacity),
              ),
            ),
            if (entry.weeklyCompletions > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${entry.weeklyCompletions}×',
                style: TextStyle(
                  fontSize: 9,
                  color: fruit.color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Weekly Summary ─────────────────────────────────────────────────────────────

class _WeeklySummary extends StatelessWidget {
  final FruitPortfolio portfolio;

  const _WeeklySummary({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final activeFruits = portfolio.activeFruits.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Your habits and practices this week touched on $activeFruits ${activeFruits == 1 ? 'fruit' : 'fruits'}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: MyWalkColor.softGold.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined,
              size: 48, color: MyWalkColor.sage.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          const Text(
            "Your habits aren't connected to the fruit yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.warmWhite),
          ),
          const SizedBox(height: 8),
          Text(
            'Want to add some purpose?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: MyWalkColor.softGold.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FruitLibraryView()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse the fruit library',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
