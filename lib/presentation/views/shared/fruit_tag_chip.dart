import 'package:flutter/material.dart';
import '../../../domain/entities/fruit.dart';
import '../../theme/app_theme.dart';

/// A single tappable chip for selecting a Fruit of the Spirit tag.
///
/// [isSelected] — chip is active (fruit.color tinted bg, bold label)
/// [isSuggested] — chip has a suggestion hint but is not yet selected
/// [onTap] — called when the chip is tapped
class FruitTagChip extends StatelessWidget {
  final FruitType fruit;
  final bool isSelected;
  final bool isSuggested;
  final VoidCallback onTap;

  const FruitTagChip({
    super.key,
    required this.fruit,
    required this.isSelected,
    this.isSuggested = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fruitColor = fruit.color;

    Color bgColor;
    Border border;

    if (isSelected) {
      bgColor = fruitColor.withValues(alpha: 0.18);
      border = Border.all(color: fruitColor, width: 1.5);
    } else if (isSuggested) {
      bgColor = MyWalkColor.golden.withValues(alpha: 0.06);
      border = Border.all(color: MyWalkColor.golden.withValues(alpha: 0.45), width: 1);
    } else {
      bgColor = Colors.transparent;
      border = Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fruit.icon,
              size: 11,
              color: isSelected ? fruitColor : MyWalkColor.softGold.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Text(
              fruit.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? fruitColor : MyWalkColor.softGold.withValues(alpha: 0.75),
              ),
            ),
            if (isSuggested && !isSelected) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'suggested',
                  style: TextStyle(
                    fontSize: 8,
                    color: MyWalkColor.golden.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
