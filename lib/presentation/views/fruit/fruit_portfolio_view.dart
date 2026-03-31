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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Text(
                  'Your habits are cultivating these fruits.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: MyWalkColor.softGold.withValues(alpha: 0.5),
                  ),
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

            // Neglected fruits section
            if (portfolio.neglectedFruits.isNotEmpty)
              SliverToBoxAdapter(
                child: _NeglectedSection(portfolio: portfolio),
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
      bgColor = fruit.color.withValues(alpha: 0.10);
      border = Border.all(color: fruit.color, width: 1.5);
      iconOpacity = 1.0;
    } else if (isDormant) {
      bgColor = MyWalkColor.warmWhite.withValues(alpha: 0.04);
      border = Border.all(color: Colors.white.withValues(alpha: 0.12));
      iconOpacity = 0.7;
    } else {
      bgColor = Colors.transparent;
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        style: BorderStyle.solid,
      );
      iconOpacity = 0.35;
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
              child: Icon(fruit.icon, size: 24, color: isActive ? fruit.color : MyWalkColor.softGold),
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
                color: isActive
                    ? fruit.color
                    : MyWalkColor.warmWhite.withValues(alpha: iconOpacity * 0.8),
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
    final balance = portfolio.weeklyBalance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$activeFruits ${activeFruits == 1 ? 'fruit' : 'fruits'} cultivated this week  ·  $balance% balanced orchard',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: MyWalkColor.softGold.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

// ── Neglected Section ──────────────────────────────────────────────────────────

class _NeglectedSection extends StatelessWidget {
  final FruitPortfolio portfolio;

  const _NeglectedSection({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final neglected = portfolio.neglectedFruits;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FRUITS TO CULTIVATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: MyWalkColor.softGold.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "These fruits aren't missing — they're waiting. Add a small practice when you're ready.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: neglected
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => FruitLibraryView(initialFruit: f)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: f.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: f.color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(f.icon, size: 12, color: f.color),
                                const SizedBox(width: 6),
                                Text(f.label,
                                    style: TextStyle(
                                        fontSize: 12, color: f.color)),
                                const SizedBox(width: 6),
                                Icon(Icons.add,
                                    size: 12,
                                    color: f.color.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
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
