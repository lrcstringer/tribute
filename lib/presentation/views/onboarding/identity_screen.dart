import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IdentityScreen extends StatefulWidget {
  /// Called with (name, selections) when the user taps "That's me".
  final void Function(String name, List<String> selections) onContinue;
  final VoidCallback onSkip;

  /// Name pre-filled from the sign-in provider (Apple / Google display name).
  final String? prefilledName;

  const IdentityScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
    this.prefilledName,
  });

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final Set<String> _selectedOptions = {};
  String _name = '';

  static const _options = [
    ('body', 'Taking better care of my body', Icons.directions_run_rounded),
    ('word', "Getting into God's Word more", Icons.menu_book_rounded),
    ('breaking', "Breaking a habit that's holding me back", Icons.shield_rounded),
    ('rest', 'Learning to actually rest', Icons.nightlight_rounded),
    ('discipline', 'Building discipline as an act of worship', Icons.local_fire_department_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _name = widget.prefilledName ?? '';
    // Show the name bottom sheet after the first frame so the screen is visible first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNameSheet());
  }

  Future<void> _showNameSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameBottomSheet(
        initial: _name,
        onSave: (name) {
          if (mounted) setState(() => _name = name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _name.isNotEmpty ? 'What is God working on\nin your life, $_name?' : 'What is God working on\nin your life right now?';

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: _showNameSheet,
              child: Row(children: [
                Expanded(
                  child: Text(
                    greeting,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.warmWhite, height: 1.3),
                  ),
                ),
                Icon(Icons.edit_rounded,
                    size: 16, color: TributeColor.golden.withValues(alpha: 0.5)),
              ]),
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
                    : () => widget.onContinue(_name, _selectedOptions.toList()),
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
            onPressed: () => widget.onSkip(),
            child: Text('Skip for now',
                style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.5))),
          ),
        ]),
      ),
    ]);
  }
}

// ── Name Bottom Sheet ─────────────────────────────────────────────────────────

class _NameBottomSheet extends StatefulWidget {
  final String initial;
  final void Function(String) onSave;

  const _NameBottomSheet({required this.initial, required this.onSave});

  @override
  State<_NameBottomSheet> createState() => _NameBottomSheetState();
}

class _NameBottomSheetState extends State<_NameBottomSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF252535),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle bar
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "What should we call you?",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: TributeColor.warmWhite),
        ),
        const SizedBox(height: 6),
        Text(
          "We\u2019ll use your first name to personalise your experience.",
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: TributeColor.warmWhite, fontSize: 17),
          decoration: InputDecoration(
            hintText: 'Your first name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: TributeColor.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TributeColor.cardBorder, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TributeColor.cardBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TributeColor.golden.withValues(alpha: 0.4), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: TributeColor.golden,
              foregroundColor: TributeColor.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  void _save() {
    widget.onSave(_ctrl.text.trim());
    Navigator.of(context).pop();
  }
}
