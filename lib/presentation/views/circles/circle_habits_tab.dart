import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/circle_habits_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../../domain/services/week_id_service.dart';
import '../../theme/app_theme.dart';

class CircleHabitsTab extends StatelessWidget {
  final String circleId;
  final bool isAdmin;
  const CircleHabitsTab({super.key, required this.circleId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Consumer<CircleHabitsProvider>(
      builder: (context, provider, _) {
        final uid = AuthService.shared.userId ?? '';
        final habits = provider.habitsFor(circleId);
        final isLoading = provider.isLoading(circleId);
        final today = WeekIdService.todayStr();

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: isAdmin
              ? FloatingActionButton.small(
                  onPressed: () => _showCreateSheet(context),
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  child: const Icon(Icons.add),
                )
              : null,
          body: isLoading && habits.isEmpty
              ? const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              : RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => provider.load(circleId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (habits.isEmpty)
                        _emptyState()
                      else
                        ...habits.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CircleHabitCard(
                            habit: h, circleId: circleId, uid: uid,
                            today: today, isAdmin: isAdmin),
                        )),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.check_circle_outline_rounded, size: 40,
            color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text('No circle habits yet.',
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text(isAdmin
            ? 'Tap + to create a shared habit for your circle.'
            : 'Your admin hasn\'t created any habits yet.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => CreateCircleHabitSheet(circleId: circleId),
    );
  }
}

// ─── Circle Habit Card ────────────────────────────────────────────────────────

class _CircleHabitCard extends StatelessWidget {
  final CircleHabit habit;
  final String circleId;
  final String uid;
  final String today;
  final bool isAdmin;

  const _CircleHabitCard({
    required this.habit, required this.circleId,
    required this.uid, required this.today, required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CircleHabitsProvider>();
    final summary = provider.summaryFor(circleId, habit.id, today);
    final hasCompleted = summary?.hasCompleted(uid) ?? false;
    final completedCount = summary?.completedCount ?? 0;
    final totalMembers = summary?.totalMembers ?? 0;
    final completionRate = summary?.completionRate ?? 0.0;

    final scheduled = habit.isScheduledFor(DateTime.now().weekday % 7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasCompleted
            ? MyWalkColor.sage.withValues(alpha: 0.06)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCompleted
              ? MyWalkColor.sage.withValues(alpha: 0.2)
              : MyWalkColor.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(habit.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite)),
          ),
          if (isAdmin)
            GestureDetector(
              onTap: () => _confirmDeactivate(context),
              child: Icon(Icons.more_horiz_rounded, size: 18,
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
        ]),
        if (habit.description != null) ...[
          const SizedBox(height: 4),
          Text(habit.description!,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ],
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(
              completionRate >= 0.8 ? MyWalkColor.golden : MyWalkColor.sage),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Text('$completedCount${totalMembers > 0 ? '/$totalMembers' : ''} completed today',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
          const Spacer(),
          if (!hasCompleted && scheduled)
            GestureDetector(
              onTap: () => context.read<CircleHabitsProvider>().complete(
                circleId: circleId, habitId: habit.id, value: 1, uid: uid),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: MyWalkColor.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MyWalkColor.sage.withValues(alpha: 0.3)),
                ),
                child: const Text('Done Today',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MyWalkColor.sage)),
              ),
            )
          else if (hasCompleted)
            Row(children: [
              const Icon(Icons.check_circle_rounded, size: 14, color: MyWalkColor.sage),
              const SizedBox(width: 4),
              const Text('Done', style: TextStyle(fontSize: 12, color: MyWalkColor.sage)),
            ])
          else
            Text('Not scheduled today',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
      ]),
    );
  }

  void _confirmDeactivate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Deactivate Habit',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text('Remove "${habit.name}" from your circle?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CircleHabitsProvider>().deactivate(circleId, habit.id);
            },
            child: const Text('Remove', style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }
}

// ─── Create Circle Habit Sheet ────────────────────────────────────────────────

class CreateCircleHabitSheet extends StatefulWidget {
  final String circleId;
  const CreateCircleHabitSheet({super.key, required this.circleId});

  @override
  State<CreateCircleHabitSheet> createState() => _CreateCircleHabitSheetState();
}

class _CreateCircleHabitSheetState extends State<CreateCircleHabitSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _purposeController = TextEditingController();
  CircleHabitTrackingType _tracking = CircleHabitTrackingType.checkIn;
  CircleHabitFrequency _frequency = CircleHabitFrequency.daily;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('New Circle Habit',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Create',
                    style: TextStyle(color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16,
            MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Habit Name'),
          const SizedBox(height: 6),
          TextField(controller: _nameController,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('e.g. Morning Prayer')),
          const SizedBox(height: 14),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextField(controller: _descController, maxLines: 2,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('What is this habit about?')),
          const SizedBox(height: 14),
          _label('Tracking Type'),
          const SizedBox(height: 8),
          _trackingSelector(),
          const SizedBox(height: 14),
          _label('Frequency'),
          const SizedBox(height: 8),
          _frequencySelector(),
          const SizedBox(height: 14),
          _label('Purpose Statement (optional)'),
          const SizedBox(height: 6),
          TextField(controller: _purposeController, maxLines: 2,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: _inputDec('Why is this habit important for your circle?')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden, foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Habit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _trackingSelector() {
    return Row(children: CircleHabitTrackingType.values.map((t) {
      final selected = _tracking == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tracking = t),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? MyWalkColor.golden.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? MyWalkColor.golden.withValues(alpha: 0.4) : Colors.transparent),
            ),
            child: Center(child: Text(_trackingLabel(t),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: selected ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5)))),
          ),
        ),
      );
    }).toList());
  }

  Widget _frequencySelector() {
    return Row(children: CircleHabitFrequency.values.map((f) {
      final selected = _frequency == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _frequency = f),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? MyWalkColor.sage.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? MyWalkColor.sage.withValues(alpha: 0.4) : Colors.transparent),
            ),
            child: Center(child: Text(_frequencyLabel(f),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: selected ? MyWalkColor.sage : Colors.white.withValues(alpha: 0.5)))),
          ),
        ),
      );
    }).toList());
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5)));

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
    filled: true, fillColor: MyWalkColor.inputBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );

  String _trackingLabel(CircleHabitTrackingType t) {
    switch (t) {
      case CircleHabitTrackingType.checkIn: return 'Check-In';
      case CircleHabitTrackingType.timed: return 'Timed';
      case CircleHabitTrackingType.count: return 'Count';
    }
  }

  String _frequencyLabel(CircleHabitFrequency f) {
    switch (f) {
      case CircleHabitFrequency.daily: return 'Daily';
      case CircleHabitFrequency.weekly: return 'Weekly';
      case CircleHabitFrequency.specificDays: return 'Specific';
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Name required.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<CircleHabitsProvider>().createHabit(
        circleId: widget.circleId, name: name, trackingType: _tracking,
        frequency: _frequency,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        purposeStatement: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}
