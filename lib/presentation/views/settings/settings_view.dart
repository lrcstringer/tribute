import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/repositories/user_preferences_repository.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/services/milestone_service.dart';
import '../../../data/datasources/local/notification_service.dart';
import '../../theme/app_theme.dart';
import '../shared/mywalk_paywall_view.dart';

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
  List<Habit> _archivedHabits = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkNotifStatus();
    _loadArchivedHabits();
  }

  Future<void> _loadArchivedHabits() async {
    final habits = await context.read<HabitProvider>().loadArchivedHabits();
    if (mounted) setState(() => _archivedHabits = habits);
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
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Reset All Data', style: TextStyle(color: MyWalkColor.warmWhite)),
        content: Text(
          'This will permanently delete all your habits, practices, and progress. This cannot be undone.',
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
            child: const Text('Reset Everything', style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    final provider = context.read<HabitProvider>();
    final fruit = context.read<FruitPortfolioProvider>();
    final prefs = context.read<UserPreferencesRepository>();

    await Future.wait([
      provider.resetAllData(),
      fruit.reset(),
    ]);

    await Future.wait([
      prefs.remove('tribute_reminders_enabled'),
      prefs.remove('tribute_reminder_hour'),
      prefs.remove('tribute_reminder_minute'),
      prefs.remove('tribute_onboarding_date'),
    ]);

    if (mounted) setState(() => _remindersEnabled = false);
    await NotificationService.shared.cancelDailyReminders();
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: MyWalkColor.cardBackground,
          title: const Text('Data Reset', style: TextStyle(color: MyWalkColor.warmWhite)),
          content: Text('All data has been cleared. Your subscription status is unchanged.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: MyWalkColor.golden)),
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
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            title: const Text('Settings',
                style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 22, fontWeight: FontWeight.w700)),
            floating: true, snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Brand header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: MyWalkDecorations.card,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('MyWalk',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
                    Text('Track your habits. Give them to God.',
                        style: TextStyle(fontSize: 14, color: MyWalkColor.softGold.withValues(alpha: 0.7))),
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
                if (_archivedHabits.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionHeader('Archived Habits'),
                  const SizedBox(height: 8),
                  _archivedHabitsSection(),
                ],
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
          decoration: MyWalkDecorations.card,
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.sage.withValues(alpha: 0.15)),
              child: const Icon(Icons.person_rounded, size: 18, color: MyWalkColor.sage),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.displayName ?? 'Signed In',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
              Text(AuthService.isApplePlatform ? 'Apple Account' : 'Google Account',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ])),
            const Icon(Icons.check_circle_rounded, color: MyWalkColor.sage, size: 18),
          ]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => auth.signOut(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: MyWalkDecorations.card,
            child: Row(children: [
              const Icon(Icons.logout_rounded, size: 16, color: MyWalkColor.warmCoral),
              const SizedBox(width: 10),
              const Text('Sign Out', style: TextStyle(fontSize: 14, color: MyWalkColor.warmCoral)),
            ]),
          ),
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.warning_amber, size: 14, color: MyWalkColor.warmCoral),
            const SizedBox(width: 6),
            Text(auth.error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ]),
        ],
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
          child: const Icon(Icons.apple_rounded, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sign in with Apple',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
          Text('Required for Prayer Circles & backup',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
        ])),
        auth.isLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden))
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
            color: MyWalkColor.golden.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.golden.withValues(alpha: 0.15)),
              child: const Icon(Icons.workspace_premium_rounded, size: 18, color: MyWalkColor.golden),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MyWalk Pro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.golden)),
              Text('All premium features unlocked',
                  style: TextStyle(fontSize: 12, color: MyWalkColor.softGold)),
            ])),
            const Icon(Icons.verified_rounded, color: MyWalkColor.golden, size: 18),
          ]),
        )
      else
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: MyWalkColor.charcoal,
            builder: (_) => const MyWalkPaywallView(),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: MyWalkDecorations.card,
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.golden.withValues(alpha: 0.1)),
                child: Icon(Icons.workspace_premium_outlined, size: 18, color: MyWalkColor.golden.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Upgrade to Pro',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
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
          decoration: MyWalkDecorations.card,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.refresh_rounded, size: 16, color: MyWalkColor.softGold),
              const SizedBox(width: 10),
              Text('Restore Purchases', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
              const Spacer(),
              if (store.isLoading)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden)),
            ]),
            if (store.error != null) ...[
              const SizedBox(height: 6),
              Text(store.error!,
                  style: const TextStyle(fontSize: 11, color: MyWalkColor.warmCoral)),
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _remindersSection() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: MyWalkDecorations.card,
        child: Row(children: [
          const Icon(Icons.notifications_rounded, size: 16, color: MyWalkColor.golden),
          const SizedBox(width: 10),
          const Expanded(child: Text('Daily Reminders',
              style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite))),
          Switch(
            value: _remindersEnabled,
            onChanged: (v) { setState(() => _remindersEnabled = v); _savePrefs(); },
            activeThumbColor: MyWalkColor.golden,
          ),
        ]),
      ),
      if (_remindersEnabled) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: MyWalkDecorations.card,
            child: Row(children: [
              const Icon(Icons.access_time_rounded, size: 16, color: MyWalkColor.softGold),
              const SizedBox(width: 10),
              const Expanded(child: Text('Reminder Time',
                  style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite))),
              Text(_reminderTime.format(context),
                  style: const TextStyle(fontSize: 14, color: MyWalkColor.golden)),
            ]),
          ),
        ),
      ],
      if (_notifDenied && _remindersEnabled) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => AppSettings.openAppSettings(type: AppSettingsType.notification),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MyWalkColor.warmCoral.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber, size: 14, color: MyWalkColor.warmCoral),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Notifications disabled — tap to enable',
                    style: TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
              ),
              const Icon(Icons.chevron_right, size: 14, color: MyWalkColor.warmCoral),
            ]),
          ),
        ),
      ],
    ]);
  }

  Widget _archivedHabitsSection() {
    return Column(
      children: _archivedHabits.map((habit) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: MyWalkDecorations.card,
          child: Row(children: [
            Icon(_habitIcon(habit), size: 16,
                color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(habit.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.45))),
            ),
            GestureDetector(
              onTap: () async {
                await context.read<HabitProvider>().unarchiveHabit(habit);
                await _loadArchivedHabits();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: MyWalkColor.golden.withValues(alpha: 0.25), width: 0.5),
                ),
                child: const Text('Restore',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: MyWalkColor.golden)),
              ),
            ),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _habitsSection(List<Habit> habits) {
    if (habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: MyWalkDecorations.card,
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
          decoration: MyWalkDecorations.card,
          child: Row(children: [
            Icon(_habitIcon(habit), size: 16,
                color: habit.isBuiltIn ? MyWalkColor.golden : MyWalkColor.sage),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(habit.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite)),
                if (habit.isBuiltIn) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MyWalkColor.golden.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Built-in',
                        style: TextStyle(fontSize: 10, color: MyWalkColor.golden)),
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
                    color: MyWalkColor.softGold.withValues(alpha: 0.6))),
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
      decoration: MyWalkDecorations.card,
      child: Column(children: [
        _statRow(Icons.check_circle_rounded, 'Total check-ins', '$checkIns', MyWalkColor.golden),
        if (minutes > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.access_time_rounded, 'Time given', timeStr, MyWalkColor.golden),
        ],
        if (cleanDays > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.shield_rounded, 'Clean days', '$cleanDays', MyWalkColor.sage),
        ],
        if (count > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.tag_rounded, 'Total counted', '${count.toInt()}', MyWalkColor.golden),
        ],
        const SizedBox(height: 12),
        _statRow(Icons.list_rounded, 'Active habits', '$habitCount', MyWalkColor.golden),
        if (milestones > 0) ...[
          const SizedBox(height: 12),
          _statRow(Icons.star_rounded, 'Milestones reached', '$milestones', MyWalkColor.golden),
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
      decoration: MyWalkDecorations.card,
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
          color: MyWalkColor.warmCoral.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.delete_rounded, size: 16, color: MyWalkColor.warmCoral),
          const SizedBox(width: 10),
          const Expanded(child: Text('Reset All Data',
              style: TextStyle(fontSize: 14, color: MyWalkColor.warmCoral))),
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
