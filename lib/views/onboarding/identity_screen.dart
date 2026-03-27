import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IdentityScreen extends StatefulWidget {
  final void Function(List<String>) onContinue;
  final VoidCallback onSkip;

  const IdentityScreen({super.key, required this.onContinue, required this.onSkip});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final Set<String> _selectedOptions = {};

  static const _options = [
    ('body', 'Taking better care of my body', Icons.directions_run_rounded),
    ('word', "Getting into God's Word more", Icons.menu_book_rounded),
    ('breaking', "Breaking a habit that's holding me back", Icons.shield_rounded),
    ('rest', 'Learning to actually rest', Icons.nightlight_rounded),
    ('discipline', 'Building discipline as an act of worship', Icons.local_fire_department_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              "What's God working on\nin your life right now?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.warmWhite, height: 1.3),
            ),
            const SizedBox(height: 10),
            Text(
              'This helps us personalise your verses and encouragement.',
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Column(
              children: _options.map((opt) {
                final isSelected = _selectedOptions.contains(opt.$1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedOptions.remove(opt.$1);
                      } else {
                        _selectedOptions.add(opt.$1);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TributeColor.golden.withValues(alpha: 0.08)
                            : TributeColor.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? TributeColor.golden.withValues(alpha: 0.3)
                              : TributeColor.cardBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Row(children: [
                        SizedBox(
                          width: 24,
                          child: Icon(opt.$3, size: 18,
                              color: isSelected
                                  ? TributeColor.golden
                                  : TributeColor.softGold.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(opt.$2,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? TributeColor.warmWhite
                                    : Colors.white.withValues(alpha: 0.5),
                              )),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? TributeColor.golden
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle, color: TributeColor.golden),
                                  ),
                                )
                              : null,
                        ),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(children: [
          Opacity(
            opacity: _selectedOptions.isEmpty ? 0.5 : 1.0,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedOptions.isEmpty
                    ? null
                    : () => widget.onContinue(_selectedOptions.toList()),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text("That's me",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TributeColor.golden,
                  foregroundColor: TributeColor.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onSkip,
            child: Text('Skip for now',
                style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.5))),
          ),
        ]),
      ),
    ]);
  }
}
