import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../providers/habit_provider.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet showing detail for a micro-action with "Add this habit" CTA.
class MicroActionDetailSheet extends StatefulWidget {
  final MicroAction action;

  const MicroActionDetailSheet({super.key, required this.action});

  static Future<void> show(BuildContext context, MicroAction action) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MicroActionDetailSheet(action: action),
    );
  }

  @override
  State<MicroActionDetailSheet> createState() => _MicroActionDetailSheetState();
}

class _MicroActionDetailSheetState extends State<MicroActionDetailSheet> {
  bool _adding = false;

  MicroAction get _action => widget.action;

  Future<void> _addHabit() async {
    if (_adding) return;
    setState(() => _adding = true);

    try {
      final habitProvider = context.read<HabitProvider>();
      final fruitProvider = context.read<FruitPortfolioProvider>();

      // Determine category — default to custom for micro-actions.
      const category = HabitCategory.custom;
      final trackingType = _action.trackingType;
      final dailyTarget = _action.targetValue ?? 1.0;
      final targetUnit = trackingType == HabitTrackingType.timed ? 'minutes' : '';

      await habitProvider.addHabit(
        name: _action.name,
        category: category,
        trackingType: trackingType,
        purpose: _action.purposeStatement,
        dailyTarget: dailyTarget,
        targetUnit: targetUnit,
        fruitTags: [_action.fruit],
        fruitPurposeStatement: _action.purposeStatement,
        sourceType: 'micro_action_library',
        sourceActionId: _action.id,
        categoryId: 'fruit_of_the_spirit',
        categoryName: 'The Fruit of the Spirit',
        subcategoryName: _action.fruit.label,
      );

      await fruitProvider.onHabitTagsChanged([], [_action.fruit]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You're now practising \"${_action.name}\"."),
            backgroundColor: MyWalkColor.cardBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fruit = _action.fruit;
    final trackingLabel = _trackingLabel(_action.trackingType);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fruit badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: fruit.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: fruit.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(fruit.icon, size: 12, color: fruit.color),
                      const SizedBox(width: 5),
                      Text(fruit.label,
                          style: TextStyle(fontSize: 12, color: fruit.color, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: MyWalkColor.surfaceOverlay,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(trackingLabel,
                      style: TextStyle(fontSize: 11, color: MyWalkColor.softGold.withValues(alpha: 0.7))),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _action.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              _action.description,
              style: TextStyle(
                fontSize: 15,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // Purpose statement (left-border callout)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: MyWalkColor.golden.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: MyWalkColor.golden.withValues(alpha: 0.6), width: 3),
                ),
              ),
              child: Text(
                _action.purposeStatement,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: MyWalkColor.softGold.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
            ),

            // Anchor verse
            if (_action.anchorVerse != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 12, color: MyWalkColor.softGold.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Text(
                    _action.anchorVerse!,
                    style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.softGold.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Add CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _adding ? null : _addHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _adding
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(MyWalkColor.charcoal),
                        ),
                      )
                    : const Text('Add this habit',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Not for me',
                  style: TextStyle(color: MyWalkColor.softGold.withValues(alpha: 0.5), fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _trackingLabel(HabitTrackingType type) {
    switch (type) {
      case HabitTrackingType.checkIn: return 'Check-in';
      case HabitTrackingType.timed:
        final mins = widget.action.targetValue?.toInt();
        return mins != null ? '$mins min' : 'Timed';
      case HabitTrackingType.count:
        final target = widget.action.targetValue?.toInt();
        return target != null ? '×$target' : 'Count';
      case HabitTrackingType.abstain: return 'Abstain';
    }
  }
}
