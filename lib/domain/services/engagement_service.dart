import 'package:flutter/foundation.dart';
import '../entities/habit.dart';
import '../repositories/user_preferences_repository.dart';
import '../utils/seeded_rng.dart';

enum EngagementAccent { golden, sage }

class PaywallContext {
  final String title;
  final String message;
  const PaywallContext({required this.title, required this.message});
}

class EngagementMessage {
  final String icon;
  final String title;
  final String body;
  final EngagementAccent accent;
  final PaywallContext? paywallContext;

  const EngagementMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    this.paywallContext,
  });
}

class EngagementService extends ChangeNotifier {
  final UserPreferencesRepository _prefs;

  EngagementService(this._prefs);

  EngagementMessage? currentMessage;
  bool isPremium = false;
  bool _evaluating = false;

  Future<int> get daysSinceOnboarding async {
    final ms = await _prefs.getInt('tribute_onboarding_date');
    if (ms == null) return 0;
    final onboarding = DateTime.fromMillisecondsSinceEpoch(ms);
    final today = DateTime.now();
    final onboardingDay = DateTime(onboarding.year, onboarding.month, onboarding.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return todayDay.difference(onboardingDay).inDays.clamp(0, 999999);
  }

  Future<bool> get _isDismissedToday async {
    final day = await daysSinceOnboarding;
    return await _prefs.getBool('tribute_engagement_dismissed_day_$day') ?? false;
  }

  Future<void> dismissCurrentMessage() async {
    final day = await daysSinceOnboarding;
    await _prefs.setBool('tribute_engagement_dismissed_day_$day', true);
    currentMessage = null;
    notifyListeners();
  }

  Future<void> evaluateMessage(List<Habit> habits) async {
    if (_evaluating) return;
    _evaluating = true;
    try {
      await _evaluateMessageInner(habits);
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _evaluateMessageInner(List<Habit> habits) async {
    if (await _isDismissedToday) {
      currentMessage = null;
      notifyListeners();
      return;
    }

    final day = await daysSinceOnboarding;

    if (day < 1 || day > 10) {
      await _evaluateTimeMilestoneMessage(habits);
      return;
    }

    final gratitudeHabit = habits.where((h) => h.isBuiltIn && h.category == HabitCategory.gratitude).firstOrNull;
    final customHabits = habits.where((h) => !h.isBuiltIn).toList();
    final firstCustom = customHabits.firstOrNull;
    final gratitudeDays = gratitudeHabit?.totalCompletedDays() ?? 0;

    EngagementMessage? message;

    switch (day) {
      case 1:
        message = const EngagementMessage(icon: 'sun.max.fill', title: 'Day 1', body: 'Your second day of gratitude plus your first custom habit check-in. Two tributes in one day. Nice.', accent: EngagementAccent.golden);
      case 2:
        if (firstCustom != null) {
          message = EngagementMessage(icon: 'quote.opening', title: 'Remember why', body: 'You said: "${firstCustom.purposeStatement}" That\'s still true today.', accent: EngagementAccent.golden);
        } else {
          message = const EngagementMessage(icon: 'quote.opening', title: 'Day 2', body: 'Two days of showing up. God sees every one.', accent: EngagementAccent.golden);
        }
      case 3:
        if (firstCustom != null) {
          final stat = _statDescription(firstCustom);
          message = EngagementMessage(icon: 'chart.line.uptrend.xyaxis', title: 'It\'s adding up', body: 'You\'ve given God $stat through ${firstCustom.name.toLowerCase()} this week. That\'s more than most people give to any habit.', accent: EngagementAccent.golden);
        } else {
          message = const EngagementMessage(icon: 'chart.line.uptrend.xyaxis', title: 'Day 3', body: 'Three days in. Your tribute is building.', accent: EngagementAccent.golden);
        }
      case 4:
        message = EngagementMessage(icon: 'hand.raised.fill', title: 'The hard part', body: "You're in the hardest days of any new habit. But you've thanked God $gratitudeDays days straight — He sees your faithfulness.", accent: EngagementAccent.sage);
      case 5:
        message = const EngagementMessage(icon: 'heart.fill', title: 'Still here', body: "Day 5. The novelty fades, but the purpose doesn't. You're doing this for something bigger than motivation.", accent: EngagementAccent.sage);
      case 6:
        message = const EngagementMessage(icon: 'calendar', title: 'Tomorrow is special', body: 'Tomorrow is your first Look Back. Whatever it looks like, it\'s worth celebrating.', accent: EngagementAccent.golden);
      case 7:
        message = null;
      case 8:
        message = const EngagementMessage(icon: 'person.2.fill', title: "You're not alone", body: 'Having even one person praying with you makes a real difference. Start or join a Prayer Circle today.', accent: EngagementAccent.golden);
      case 9:
        message = const EngagementMessage(icon: 'person.2.fill', title: 'Community matters', body: "Accountability isn't about pressure — it's about knowing someone's in your corner. Start a Prayer Circle and invite a few people.", accent: EngagementAccent.golden);
      case 10:
        message = EngagementMessage(icon: 'star.fill', title: '10 days in', body: '10 days of gratitude. $gratitudeDays times you chose to thank God. This is when most people quit other apps. Not you.', accent: EngagementAccent.golden);
      default:
        message = null;
    }

    currentMessage = message;
    notifyListeners();
  }

  Future<void> _evaluateTimeMilestoneMessage(List<Habit> habits) async {
    final day = await daysSinceOnboarding;
    final milestoneKey = 'tribute_time_milestone_shown_$day';

    if (await _prefs.getBool(milestoneKey) ?? false) {
      await _evaluateVariableReinforcement(habits);
      return;
    }

    const freeMilestones = {7, 21, 30};
    const allMilestones = [
      (7, 'One week down', "You showed up, and God met you in it. Let\u2019s keep going."),
      (14, 'Two weeks', "You\u2019re past the point where most people quit a new app. You\u2019re still here."),
      (21, '3 weeks in', "This is usually when the newness fades and it starts to feel like work. That\u2019s normal. You\u2019re doing the hard part."),
      (30, 'A full month', "30 days of giving this to God. That\u2019s not a small thing."),
      (45, 'Over 6 weeks', 'Most people never make it this far. The rhythm is starting to take hold. Keep showing up.'),
      (66, '66 days', "Research says this is roughly when a habit becomes automatic. This isn\u2019t something you do anymore \u2014 it\u2019s who you are. Keep going."),
      (100, '100 days', "A hundred times you chose to show up. That\u2019s a life that\u2019s being changed."),
      (365, 'A full year', 'Whatever this year looked like \u2014 the strong weeks and the quiet ones \u2014 He was in all of it.'),
    ];

    final available = isPremium ? allMilestones : allMilestones.where((m) => freeMilestones.contains(m.$1)).toList();
    final milestone = available.where((m) => m.$1 == day).firstOrNull;

    if (milestone != null) {
      await _prefs.setBool(milestoneKey, true);
      PaywallContext? paywallCtx;
      if (!isPremium && milestone.$1 == 21) {
        paywallCtx = const PaywallContext(title: '3 weeks in and still going', message: 'Unlock your 52-week heatmap, detailed analytics, and see the full picture of your journey.');
      }
      currentMessage = EngagementMessage(icon: 'sparkles', title: milestone.$2, body: milestone.$3, accent: EngagementAccent.golden, paywallContext: paywallCtx);
    } else {
      await _evaluateVariableReinforcement(habits);
    }
    notifyListeners();
  }

  Future<void> _evaluateVariableReinforcement(List<Habit> habits) async {
    if (!isPremium) { currentMessage = null; notifyListeners(); return; }

    final day = await daysSinceOnboarding;
    if (day <= 14) { currentMessage = null; notifyListeners(); return; }

    final lastShown = await _prefs.getInt('tribute_variable_reinforcement_last') ?? 0;
    final daysSinceLast = day - lastShown;
    final rng = SeededRng(day * 7 + 31);
    final interval = 14 + (rng.next() % 15);
    if (daysSinceLast < interval) { currentMessage = null; notifyListeners(); return; }

    final gratitudeHabit = habits.where((h) => h.isBuiltIn && h.category == HabitCategory.gratitude).firstOrNull;
    final gratitudeDays = gratitudeHabit?.totalCompletedDays() ?? 0;
    final customHabits = habits.where((h) => !h.isBuiltIn).toList();

    final messages = <(String, String, String)>[];

    if (day >= 180) messages.add(('sparkles', 'Still here', '$day days ago you started this. You\u2019re still here. That\u2019s remarkable.'));
    if (gratitudeDays >= 100) messages.add(('heart.fill', 'Gratitude milestone', 'Your gratitude count just passed $gratitudeDays. $gratitudeDays days of thanking God. Let that sink in.'));

    for (final h in customHabits) {
      if (h.trackingType == HabitTrackingType.timed) {
        final hours = (h.totalValue() / 60).toInt();
        if (hours >= 50) messages.add(('flame.fill', 'Time given', "You\u2019ve given God $hours hours through ${h.name.toLowerCase()}. That\u2019s incredible dedication."));
      }
      if (h.trackingType == HabitTrackingType.count) {
        final total = h.totalValue().toInt();
        if (total >= 500) {
          final unit = h.targetUnit.isEmpty ? 'completed' : h.targetUnit;
          messages.add(('number', 'Count milestone', '$total $unit. Every single one counted.'));
        }
      }
    }

    if (messages.isEmpty) messages.add(('sun.max.fill', 'Keep going', 'Remember when this felt hard? Look at you now.'));

    final idx = rng.next() % messages.length;
    final (icon, title, body) = messages[idx];
    await _prefs.setInt('tribute_variable_reinforcement_last', day);
    currentMessage = EngagementMessage(icon: icon, title: title, body: body, accent: EngagementAccent.golden);
    notifyListeners();
  }

  String _statDescription(Habit habit) {
    switch (habit.trackingType) {
      case HabitTrackingType.timed:
        final mins = habit.totalValue().toInt();
        return mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '$mins minutes';
      case HabitTrackingType.count:
        final unit = habit.targetUnit.isEmpty ? 'completed' : habit.targetUnit;
        return '${habit.totalValue().toInt()} $unit';
      case HabitTrackingType.checkIn:
        return '${habit.totalCompletedDays()} days';
      case HabitTrackingType.abstain:
        return '${habit.totalCompletedDays()} clean days';
    }
  }
}

