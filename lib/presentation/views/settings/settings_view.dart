import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/repositories/user_preferences_repository.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/services/milestone_service.dart';
import '../../../data/datasources/local/notification_service.dart';
import '../../theme/app_theme.dart';
import '../shared/tribute_paywall_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const _milestoneService = MilestoneService.instance;

  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _notifDenied = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkNotifStatus();
  }

  Future<void> _loadPrefs() async {
    final prefs = context.read<UserPreferencesRepository>();
    final enabled = await prefs.getBool('tribute_reminders_enabled') ?? false;
    final hour = await prefs.getInt('tribute_reminder_hour') ?? 8;
    final minute = await prefs.getInt('tribute_reminder_minute') ?? 0;
    if (mounted) {
      setState(() {
        _remindersEnabled = enabled;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _checkNotifStatus() async {
    await NotificationService.shared.checkAuthorization();
    final authorized = NotificationService.shared.isAuthorized;
    if (mounted) setState(() => _notifDenied = !authorized);
  }

  Future<void> _savePrefs() async {
    final prefs = context.read<UserPreferencesRepository>();
    await prefs.setBool('tribute_reminders_enabled', _remindersEnabled);
    await prefs.setInt('tribute_reminder_hour', _reminderTime.hour);
    await prefs.setInt('tribute_reminder_minute', _reminderTime.minute);
    if (_remindersEnabled) {
      await NotificationService.shared.scheduleDailyReminders();
    } else {
      await NotificationService.shared.cancelDailyReminders();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) {
      setState(() => _reminderTime = picked);
      _savePrefs();
    }
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TributeColor.cardBackground,
        title: const Text('Reset All Data', style: TextStyle(color: TributeColor.warmWhite)),
        content: Text(
          'This will permanently delete all your habits, entries, and progress. This cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllData();
            },
            child: const Text('Reset Everything', style: TextStyle(color: TributeColor.warmCoral)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    final provider = context.read<HabitProvider>();
    final prefs = context.read<UserPreferencesRepository>();
    final habits = List<Habit>.from(provider.habits);
    for (final h in habits) {
      if (!h.isBuiltIn) await provider.deleteHabit(h);
    }
    await prefs.remove('tribute_reminders_enabled');
    await prefs.remove('tribute_reminder_hour');
    await prefs.remove('tribute_reminder_minute');
    if (mounted) setState(() => _remindersEnabled = false);
    await NotificationService.shared.cancelDailyReminders();
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: TributeColor.cardBackground,
          title: const Text('Data Reset', style: TextStyle(color: TributeColor.warmWhite)),
          content: Text('All data has been cleared. Your subscription status is unchanged.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: TributeColor.golden)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().sortedHabits;
    final store = context.watch<StoreProvider>();
    final auth = context.watch<AuthService>();

    final totalCheckIns = habits.fold<int>(0, (s, h) => s + h.totalCompletedDays());
    final totalMinutes = habits
        .where((h) => h.trackingType == HabitTrackingType.timed)
        .fold<double>(0, (s, h) => s + h.totalValue());
    final totalCleanDays = habits
        .where((h) => h.trackingType == HabitTrackingType.abstain)
        .fold<int>(0, (s, h) => s + h.totalCompletedDays());
    final totalCount = habits
        .where((h) => h.trackingType == HabitTrackingType.count)
        .fold<double>(0, (s, h) => s + h.totalValue());
    final milestoneCount = habits
        .expand((h) => _milestoneService.milestones(h).where((m) => m.isReached))
        .length;

    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: TributeColor.charcoal,
            title: const Text('Settings',
                style: TextStyle(color: TributeColor.warmWhite, fontSize: 22, fontWeight: FontWeight.w700)),
            floating: true, snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Brand header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: TributeDecorations.card,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('TRIBUTE',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: TributeColor.golden)),
                    Text('Track your habits. Give them to God.',
                        style: TextStyle(fontSize: 14, color: TributeColor.softGold.withValues(alpha: 0.7))),
                  ]),
                ),
                const SizedBox(height: 20),
                _sectionHeader('Account'),
                const SizedBox(height: 8),
                _accountSection(auth),
                const SizedBox(height: 20),
                _sectionHeader('Subscription'),
                const SizedBox(height: 8),
                _subscriptionSection(store),
                const SizedBox(height: 20),
                _sectionHeader('Reminders'),
                const SizedBox(height: 8),
                _remindersSection(),
                const SizedBox(height: 20),
                _sectionHeader('Your Habits'),
                const SizedBox(height: 8),
                _habitsSection(habits.toList()),
                const SizedBox(height: 20),
                _sectionHeader('Lifetime Stats'),
                const SizedBox(height: 8),
                _statsSection(totalCheckIns, totalMinutes, totalCleanDays, totalCount, milestoneCount, habits.length),
                const SizedBox(height: 20),
                _sectionHeader('About'),
                const SizedBox(height: 8),
                _infoRow('Version', '1.0.0'),
                const SizedBox(height: 20),
                _resetButton(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2));
  }

  Widget _accountSection(AuthService auth) {
    if (auth.isAuthenticated) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: TributeDecorations.card,
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: TributeColor.sage.withValues(alpha: 0.15)),
              child: const Icon(Icons.person_rounded, size: 18, color: TributeColor.sage),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.displayName ?? 'Signed In',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
              Text('Apple Account', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ])),
            const Icon(Icons.check_circle_rounded, color: TributeColor.sage, size: 18),
          ]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => auth.signOut(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: TributeDecorations.card,
            child: Row(children: [
              const Icon(Icons.logout_rounded, size: 16, color: TributeColor.warmCoral),
              const SizedBox(width: 10),
              const Text('Sign Out', style: TextStyle(fontSize: 14, color: TributeColor.warmCoral)),
            ]),
          ),
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.warning_amber, size: 14, color: TributeColor.warmCoral),
            const SizedBox(width: 6),
            Text(auth.error!, style: const TextStyle(fontSize: 12, color: TributeColor.warmCoral)),
          ]),
        ],
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TributeDecorations.card,
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
          child: const Icon(Icons.apple_rounded, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sign in with Apple',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
          Text('Required for Prayer Circles & backup',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
        ])),
        auth.isLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.golden))
            : Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
      ]),
    );
  }

  Widget _subscriptionSection(StoreProvider store) {
    return Column(children: [
      if (store.isPremium)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TributeColor.golden.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TributeColor.golden.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: TributeColor.golden.withValues(alpha: 0.15)),
              child: const Icon(Icons.workspace_premium_rounded, size: 18, color: TributeColor.golden),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tribute Pro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.golden)),
              Text('All premium features unlocked',
                  style: TextStyle(fontSize: 12, color: TributeColor.softGold)),
            ])),
            const Icon(Icons.verified_rounded, color: TributeColor.golden, size: 18),
          ]),
        )
      else
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context, isScrollControlled: true, backgroundColor: TributeColor.charcoal,
            builder: (_) => const TributePaywallView(),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: TributeDecorations.card,
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: TributeColor.golden.withValues(alpha: 0.1)),
                child: Icon(Icons.workspace_premium_outlined, size: 18, color: TributeColor.golden.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Upgrade to Pro',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
                Text('Unlimited habits, SOS, analytics & more',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
              ])),
              Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: store.isLoading ? null : () => store.restore(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: TributeDecorations.card,
          child: Row(children: [
            const Icon(Icons.refresh_rounded, size: 16, color: TributeColor.softGold),
            const SizedBox(width: 10),
            Text('Restore Purchases', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
            const Spacer(),
            if (store.isLoading)
              const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.golden)),
          ]),
        ),
      ),
    ]);
  }

  Widget _remindersSection() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: TributeDecorations.card,
        child: Row(children: [
          const Icon(Icons.notifications_rounded, size: 16, color: TributeColor.golden),
          const SizedBox(width: 10),
          const Expanded(child: Text('Daily Reminders',
              style: TextStyle(fontSize: 14, color: TributeColor.warmWhite))),
          Switch(
            value: _remindersEnabled,
            onChanged: (v) { setState(() => _remindersEnabled = v); _savePrefs(); },
            activeThumbColor: TributeColor.golden,
          ),
        ]),
      ),
      if (_remindersEnabled) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: TributeDecorations.card,
            child: Row(children: [
              const Icon(Icons.access_time_rounded, size: 16, color: TributeColor.softGold),
              const SizedBox(width: 10),
              const Expanded(child: Text('Reminder Time',
                  style: TextStyle(fontSize: 14, color: TributeColor.warmWhite))),
              Text(_reminderTime.format(context),
                  style: const TextStyle(fontSize: 14, color: TributeColor.golden)),
            ]),
          ),
        ),
      ],
      if (_notifDenied && _remindersEnabled) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TributeColor.warmCoral.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber, size: 14, color: TributeColor.warmCoral),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Notifications disabled — enable in Settings',
                  style: TextStyle(fontSize: 12, color: TributeColor.warmCoral)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _habitsSection(List<Habit> habits) {
    if (habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: TributeDecorations.card,
        child: Center(
          child: Text('No habits yet',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
        ),
      );
    }
    return Column(
      children: habits.map((habit) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: TributeDecorations.card,
          child: Row(children: [
            Icon(_habitIcon(habit), size: 16,
                color: habit.isBuiltIn ? TributeColor.golden : TributeColor.sage),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(habit.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TributeColor.warmWhite)),
                if (habit.isBuiltIn) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TributeColor.golden.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Built-in',
                        style: TextStyle(fontSize: 10, color: TributeColor.golden)),
                  ),
                ],
              ]),
              Row(children: [
                Text(habit.trackingType.name,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                Text(' \u00B7 ', style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
                Text('${_milestoneService.habitAge(habit)} days',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
              ]),
            ])),
            Text(_milestoneService.lifetimeStat(habit).primaryValue,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: TributeColor.softGold.withValues(alpha: 0.6))),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _statsSection(int checkIns, double minutes, int cleanDays, double count, int milestones, int habitCount) {
    final hours = minutes ~/ 60;
    final mins = minutes.toInt() % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TributeDecorations.card,
      child: Column(children: [
        _statRow(Icons.check_circle_rounded, 'Total check-ins', '$checkIns', TributeColor.golden),
        if (minutes > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.access_time_rounded, 'Time given', timeStr, TributeColor.golden),
        ],
        if (cleanDays > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.shield_rounded, 'Clean days', '$cleanDays', TributeColor.sage),
        ],
        if (count > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.tag_rounded, 'Total counted', '${count.toInt()}', TributeColor.golden),
        ],
        const SizedBox(height: 12),
        _statRow(Icons.list_rounded, 'Active habits', '$habitCount', TributeColor.golden),
        if (milestones > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.star_rounded, 'Milestones reached', '$milestones', TributeColor.golden),
        ],
      ]),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)))),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TributeDecorations.card,
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)))),
        Text(value, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
      ]),
    );
  }

  Widget _resetButton() {
    return GestureDetector(
      onTap: _confirmReset,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TributeColor.warmCoral.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TributeColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.delete_rounded, size: 16, color: TributeColor.warmCoral),
          const SizedBox(width: 10),
          const Expanded(child: Text('Reset All Data',
              style: TextStyle(fontSize: 14, color: TributeColor.warmCoral))),
        ]),
      ),
    );
  }

  IconData _habitIcon(Habit habit) {
    if (habit.trackingType == HabitTrackingType.abstain) return Icons.shield_rounded;
    switch (habit.category) {
      case HabitCategory.gratitude: return Icons.auto_awesome;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      case HabitCategory.abstain: return Icons.shield_rounded;
      case HabitCategory.custom: return Icons.star;
    }
  }
}
