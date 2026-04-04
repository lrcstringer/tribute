import 'package:flutter/material.dart';
import '../../../domain/entities/beatitude.dart';
import '../../theme/app_theme.dart';
import 'beatitude_detail_view.dart';

const _kAccent = Color(0xFF9B8BB4);

class BeatitudesView extends StatelessWidget {
  const BeatitudesView({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'assets/beatitudes_golden_etched_separate/Beatitudes.jpg',
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
                          'The Beatitudes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Matthew 5:3\u201312',
                          style: TextStyle(
                            fontSize: 14,
                            color: MyWalkColor.golden.withValues(alpha: 0.85),
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
                  Text(
                    'In the most famous sermon ever preached, Jesus opened with eight declarations that turned the world\u2019s values upside down. The Beatitudes are not rules to follow or achievements to unlock \u2014 they are a portrait of a life shaped by the Kingdom of God.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'They move from the inside out: beginning with humility before God, moving through surrender and desire, and flowing outward into mercy, peace and costly faithfulness in the world.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap any Beatitude to explore what Jesus meant, what it looks like in daily life, and how to grow into it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
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
                          'Learn more about the Beatitudes',
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

          // ── 4 rows × 2 cards ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final b = kBeatitudes[i];
                  return _BeatitudeCard(
                    beatitude: b,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BeatitudeDetailView(beatitude: b),
                      ),
                    ),
                  );
                },
                childCount: kBeatitudes.length,
              ),
            ),
          ),
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
                  Icon(Icons.self_improvement, size: 18, color: _kAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The Beatitudes',
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
                'What Jesus was saying and why it still matters',
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
                  _para('On a hillside in Galilee, surrounded by crowds of ordinary people \u2014 farmers, fishermen, the poor, the sick, the overlooked \u2014 Jesus sat down and began to teach. What followed was the most concentrated, radical and counter-cultural ethical teaching in human history. We call it the Sermon on the Mount.'),
                  _para('He opened it with eight statements, each beginning with the word blessed. We call them the Beatitudes, from the Latin beatus \u2014 happy, fortunate, to be envied.'),
                  _para('But the people Jesus called blessed were not who anyone expected.'),
                  _italicPara('Blessed are the poor in spirit. The mourning. The meek. Those who hunger for righteousness. The merciful. The pure in heart. The peacemakers. The persecuted.'),
                  _para('These are not the powerful, the successful, the admired or the comfortable. Jesus is declaring that the Kingdom of God belongs to people the world overlooks \u2014 and more than that, He is describing the kind of person the Kingdom produces.'),
                  _heading('The Beatitudes are not a checklist.'),
                  _para('Jesus is not giving eight commands and saying \u201cachieve these states and God will reward you.\u201d He is painting a portrait \u2014 describing from the inside out what a person looks like when the Kingdom of God has truly taken up residence in their soul.'),
                  _para('Read together, they tell a story. They move in a deliberate direction:'),
                  _para('The first two \u2014 poor in spirit and mourning \u2014 describe coming to God with nothing held back. Empty hands. Honest grief. The posture of someone who has stopped pretending.'),
                  _para('The next two \u2014 meek and hungry for righteousness \u2014 describe what happens inside as that person is formed: their will surrendered, their desire sharpened toward God and His ways.'),
                  _para('The fifth and sixth \u2014 merciful and pure in heart \u2014 describe what begins to flow outward: grace given freely to others, and an inner life with nothing hidden.'),
                  _para('The final two \u2014 peacemakers and persecuted \u2014 describe engaging the world at real cost, for the sake of the Kingdom.'),
                  _para('This is a biography of transformation. Not a formula for earning God\u2019s favour, but a description of what a life looks like when the Spirit is at work.'),
                  _heading('Jesus himself is the fulfilment of every Beatitude.'),
                  _para('He was poor in spirit \u2014 completely dependent on the Father. He mourned over Jerusalem, over Lazarus, over sin. He was the meekest man who ever lived \u2014 all authority in heaven and earth, yet He washed feet. He hungered for righteousness, showed mercy without limit, was utterly pure in heart, made peace between God and humanity at the cost of His own life, and was persecuted unto death.'),
                  _para('The Beatitudes are not first a description of what you must become. They are first a description of who Jesus already is \u2014 and the invitation is to be conformed to His image.'),
                  _heading('What this means for how you use this section:'),
                  _para('You cannot work your way into being poor in spirit or pure in heart any more than you can manufacture the Fruit of the Spirit. These qualities are the outcome of a life genuinely oriented toward God.'),
                  _para('But the practices you build \u2014 in prayer, in Scripture, in service, in community \u2014 are the conditions in which the Spirit does this forming work. Each Beatitude in this section offers a reflection question, a set of practices and supporting Scripture to help you not just understand it, but begin to live in its direction.'),
                  _para('The goal is not to tick off eight beatitudes. The goal is to become, slowly and by grace, the kind of person Jesus was describing on that hillside two thousand years ago.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _para(String text) => Padding(
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

  Widget _italicPara(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 3),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: _kAccent.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
        ),
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MyWalkColor.warmWhite,
            height: 1.4,
          ),
        ),
      );
}

// ── Beatitude Card ────────────────────────────────────────────────────────────

class _BeatitudeCard extends StatelessWidget {
  final BeatitudeModel beatitude;
  final VoidCallback onTap;

  const _BeatitudeCard({required this.beatitude, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _kAccent.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Image.asset(
                  beatitude.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                color: MyWalkColor.cardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beatitude.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      beatitude.verseRef,
                      style: TextStyle(
                        fontSize: 10,
                        color: _kAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
