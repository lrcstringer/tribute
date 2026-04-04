import 'package:flutter/material.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../theme/app_theme.dart';
import 'micro_action_detail_sheet.dart';
import '../habits/add_habit_view.dart';

/// Full-screen micro-action browser, organised by fruit tab.
class FruitLibraryView extends StatefulWidget {
  /// Optional initial filter — opens directly to that fruit tab.
  final FruitType? initialFruit;

  const FruitLibraryView({super.key, this.initialFruit});

  @override
  State<FruitLibraryView> createState() => _FruitLibraryViewState();
}

class _FruitLibraryViewState extends State<FruitLibraryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialFruit != null
        ? FruitType.values.indexOf(widget.initialFruit!)
        : 0;
    _tabController = TabController(
      length: FruitType.values.length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, FruitType.values.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text(
          'Cultivate the Fruit of the Spirit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: MyWalkColor.golden,
            indicatorWeight: 2,
            labelColor: MyWalkColor.golden,
            unselectedLabelColor: MyWalkColor.softGold.withValues(alpha: 0.5),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: FruitType.values
                .map((f) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f.icon, size: 13),
                          const SizedBox(width: 5),
                          Text(f.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Small practices that make space for the Spirit.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: MyWalkColor.softGold.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: FruitType.values.map((fruit) => _fruitPage(fruit)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fruitPage(FruitType fruit) {
    final actions = MicroActionLibrary.actionsFor(fruit);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: actions.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == actions.length) return _customPracticeCard(context, fruit);
        return _MicroActionCard(action: actions[i]);
      },
    );
  }

  Widget _customPracticeCard(BuildContext context, FruitType fruit) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: MyWalkColor.charcoal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (_, sc) => AddHabitView(
            scrollController: sc,
            prefilledCategoryId: 'fruit_of_the_spirit',
            prefilledCategoryName: 'The Fruit of the Spirit',
            prefilledSubcategoryName: fruit.label,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyWalkColor.golden.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.add_circle_outline, size: 18, color: MyWalkColor.golden),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create My Own Practice',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: MyWalkColor.warmWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Name it, set a goal, and make it yours.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _MicroActionCard extends StatelessWidget {
  final MicroAction action;

  const _MicroActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final fruit = action.fruit;
    return GestureDetector(
      onTap: () => MicroActionDetailSheet.show(context, action),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MyWalkColor.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fruit icon circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fruit.color.withValues(alpha: 0.12),
              ),
              child: Icon(fruit.icon, size: 16, color: fruit.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: MyWalkColor.warmWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _trackingBadge(action),
                      const SizedBox(width: 6),
                      _freqBadge(action),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.add_circle_outline,
                size: 20, color: MyWalkColor.golden.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _trackingBadge(MicroAction action) {
    String label;
    switch (action.trackingType) {
      case HabitTrackingType.checkIn:
        label = 'Check-in';
      case HabitTrackingType.timed:
        final mins = action.targetValue?.toInt();
        label = mins != null ? '$mins min' : 'Timed';
      case HabitTrackingType.count:
        final t = action.targetValue?.toInt();
        label = t != null ? '×$t' : 'Count';
      case HabitTrackingType.abstain:
        label = 'Abstain';
    }
    return _badge(label);
  }

  Widget _freqBadge(MicroAction action) =>
      _badge(action.defaultFrequency == 'weekly' ? 'Weekly' : 'Daily');

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: MyWalkColor.surfaceOverlay,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 10, color: MyWalkColor.softGold.withValues(alpha: 0.65))),
      );
}
