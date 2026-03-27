import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CoreMechanicsScreen extends StatefulWidget {
  final VoidCallback onNext;
  const CoreMechanicsScreen({super.key, required this.onNext});

  @override
  State<CoreMechanicsScreen> createState() => _CoreMechanicsScreenState();
}

class _CoreMechanicsScreenState extends State<CoreMechanicsScreen> {
  final _pageController = PageController();
  int _currentPanel = 0;
  double _counterValue = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPanel = index);
    if (index == 1) {
      setState(() => _counterValue = 0);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _counterValue = 247);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            _weeklyRhythmPanel(),
            _timeAddsUpPanel(),
            _prayerCirclesPanel(),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _currentPanel;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? TributeColor.golden : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentPanel == 2
                ? Padding(
                    key: const ValueKey('continue'),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TributeColor.golden,
                          foregroundColor: TributeColor.charcoal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('hint'),
                    height: 48,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Swipe to continue',
                          style: TextStyle(fontSize: 15, color: TributeColor.softGold.withValues(alpha: 0.5))),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 14,
                          color: TributeColor.softGold.withValues(alpha: 0.4)),
                    ]),
                  ),
          ),
        ]),
      ),
    ]);
  }

  Widget _weeklyRhythmPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        const Icon(Icons.calendar_month_rounded, size: 56, color: TributeColor.golden),
        const SizedBox(height: 24),
        const Text(
          'Every week is an offering,\nnot a scorecard.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.softGold),
        ),
        const SizedBox(height: 16),
        Text(
          'Every Sunday you set your intention. Monday through Saturday you check in \u2014 each one is a small gift to God. The next Sunday you look back. 5 out of 7? That\u2019s a beautiful week.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.75), height: 1.6),
        ),
        const SizedBox(height: 24),
        _verseFooter(
          text: 'Because of the Lord\u2019s great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.',
          reference: 'Lamentations 3:22\u201323',
        ),
      ]),
    );
  }

  Widget _timeAddsUpPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        const Icon(Icons.trending_up_rounded, size: 56, color: TributeColor.golden),
        const SizedBox(height: 24),
        const Text(
          'Every minute counts.\nEvery day counts.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.softGold),
        ),
        const SizedBox(height: 16),
        Text(
          'Tribute tracks everything you give \u2014 minutes, reps, days. Not just today, but all of it. Over weeks and months you\u2019ll see something amazing build up.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.75), height: 1.6),
        ),
        const SizedBox(height: 24),
        _animatedCounter(),
        const SizedBox(height: 24),
        _verseFooter(
          text: 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.',
          reference: 'Colossians 3:23',
        ),
      ]),
    );
  }

  Widget _animatedCounter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: TributeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TributeColor.golden.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 2000),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: Text(
            '${_counterValue.toInt()}',
            key: ValueKey(_counterValue.toInt()),
            style: const TextStyle(
              fontSize: 48, fontWeight: FontWeight.w700, color: TributeColor.golden,
            ),
          ),
        ),
        Text('minutes given',
            style: TextStyle(fontSize: 15, color: TributeColor.softGold.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _prayerCirclesPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        const Icon(Icons.groups_rounded, size: 48, color: TributeColor.golden),
        const SizedBox(height: 24),
        const Text(
          'You\u2019re not doing\nthis alone.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.softGold),
        ),
        const SizedBox(height: 16),
        Text(
          'Invite 2\u20135 people you trust to form a Prayer Circle. You\u2019ll track together, see your group\u2019s combined progress on a shared heatmap, and \u2014 if you ever need it \u2014 ask for prayer with one tap. No details shared. Just prayer.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.75), height: 1.6),
        ),
        const SizedBox(height: 16),
        Text(
          'Your circle sees the group\u2019s combined effort, not your individual habits. It\u2019s community without comparison.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 24),
        _verseFooter(
          text: 'The prayer of a righteous person is powerful and effective.',
          reference: 'James 5:16',
        ),
      ]),
    );
  }

  Widget _verseFooter({required String text, required String reference}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(children: [
        Text(
          '\u201C$text\u201D',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14, fontStyle: FontStyle.italic, height: 1.5,
            color: TributeColor.softGold.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text('\u2014 $reference',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: TributeColor.golden.withValues(alpha: 0.6))),
      ]),
    );
  }
}
