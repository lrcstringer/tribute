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
          // ── Artistic Header ──────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/TheFruit.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MyWalkColor.charcoal.withValues(alpha: 0.6),
                          MyWalkColor.charcoal,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The Fruit of the Spirit',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Galatians 5:22\u201323',
                          style: TextStyle(
                            fontSize: 14,
                            color: MyWalkColor.sage.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Intro content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // John 15:8
                  Text(
                    '\u201cThis is to my Father\u2019s glory, that you bear much fruit, showing yourselves to be my disciples.\u201d',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2014 John 15:8',
                    style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.softGold.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Galatians 5:22-23
                  Text(
                    '\u201cThe fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control.\u201d',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2014 Galatians 5:22\u201323',
                    style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.softGold.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'These nine qualities are not habits to master \u2014 they are the natural fruit of a life connected to the vine \u2014 what the Holy Spirit produces in you as you walk with God day by day, love others and trust His Word. Like fruit on a branch, they are not forced.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap any fruit to explore what it means, how to recognise the fruit growing in you, and what practices may help create the conditions for the Spirit\u2019s work in your life.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Learn more link
                  GestureDetector(
                    onTap: () => _showLearnMore(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Learn more about the Fruit of the Spirit',
                          style: TextStyle(
                            fontSize: 13,
                            color: MyWalkColor.golden.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: MyWalkColor.golden.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── Fruit grid ───────────────────────────────────────────────────
          if (provider.isLoading && portfolio == null)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: MyWalkColor.golden)),
            )
          else if (portfolio == null)
            const SliverFillRemaining(child: Center(child: _EmptyState()))
          else ...[
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

  void _showLearnMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.eco, size: 18, color: MyWalkColor.sage),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The Fruit of the Spirit',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'What it means and why it matters',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.softGold.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  _learnMorePara(
                    'In Galatians 5:22\u201323, the Apostle Paul describes nine qualities that characterise a life shaped by God\u2019s Spirit: love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control.',
                  ),
                  _learnMorePara(
                    'Notice what Paul does not say. He does not say \u201cthe works of the Spirit\u201d or \u201cthe disciplines of the Spirit.\u201d He says fruit \u2014 and that word is deliberate.',
                  ),
                  _learnMorePara(
                    'Fruit is not manufactured. It grows. It appears on a branch that is alive and connected to its source. A branch cannot produce apples by striving \u2014 it produces them by remaining in the tree, drawing on its life.',
                  ),
                  _learnMoreVerse(
                    '\u201cI am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.\u201d',
                    'John 15:5',
                  ),
                  _learnMorePara(
                    'The Fruit of the Spirit is what happens in a person who is genuinely abiding in Christ \u2014 praying, reading Scripture, worshipping, serving, confessing, loving others. The fruit is the outcome of that whole life lived with God, not a separate programme to follow.',
                  ),
                  _learnMorePara(
                    'This means two things that should encourage you:',
                  ),
                  _learnMorePara(
                    'First, you cannot earn these qualities. If you are harsh with yourself for lacking patience or joy, remember \u2014 you cannot manufacture what only the Spirit can grow. Your job is not to try harder but to stay connected.',
                  ),
                  _learnMorePara(
                    'Second, your habits and practices matter enormously \u2014 not because they produce the fruit directly, but because they are the conditions in which the Spirit works. A tree needs soil, water and light. Your spiritual practices are the soil, water and light of the soul.',
                  ),
                  _learnMorePara(
                    'The nine fruits Paul lists are not exhaustive \u2014 he could have added compassion, humility, steadfastness. But they offer a portrait of what a Spirit-shaped life looks like from the inside out. Together they describe someone who loves without condition, holds joy in all circumstances, makes peace, endures patiently, treats others with gentleness and kindness, lives with integrity, and governs their own desires with grace.',
                  ),
                  _learnMorePara(
                    'That is the kind of person Jesus was. That is who the Spirit is making you.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _learnMorePara(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            height: 1.65,
          ),
        ),
      );

  Widget _learnMoreVerse(String text, String ref) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: MyWalkColor.golden.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                  color: MyWalkColor.golden.withValues(alpha: 0.5), width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.softGold.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '\u2014 $ref',
                style: TextStyle(
                  fontSize: 11,
                  color: MyWalkColor.softGold.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
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
      bgColor = fruit.color.withValues(alpha: 0.60);
      border = Border.all(color: fruit.color, width: 1.5);
      iconOpacity = 1.0;
    } else if (isDormant) {
      bgColor = fruit.color.withValues(alpha: 0.38);
      border = Border.all(color: fruit.color.withValues(alpha: 0.85));
      iconOpacity = 1.0;
    } else {
      bgColor = fruit.color.withValues(alpha: 0.22);
      border = Border.all(color: fruit.color.withValues(alpha: 0.60));
      iconOpacity = 0.80;
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
                '${entry.weeklyCompletions}\u00d7',
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
                fontSize: 13,
                color: MyWalkColor.softGold.withValues(alpha: 0.6)),
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
