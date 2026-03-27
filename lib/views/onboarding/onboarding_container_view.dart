import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart';
import 'identity_screen.dart';
import 'reframe_screen.dart';
import 'first_gratitude_screen.dart';
import 'habit_selection_screen.dart';
import 'habit_setup_screen.dart';
import 'habit_summary_screen.dart';
import 'core_mechanics_screen.dart';
import 'notification_preferences_screen.dart';
import 'paywall_screen.dart';
import 'dedication_ceremony_screen.dart';

class OnboardingContainerView extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingContainerView({super.key, required this.onComplete});

  @override
  State<OnboardingContainerView> createState() => _OnboardingContainerViewState();
}

class _OnboardingContainerViewState extends State<OnboardingContainerView> {
  int _currentStep = 0;
  String? _gratitudeNote;
  HabitCategory? _selectedCategory;
  String _customHabitName = '';
  String _customPurpose = '';
  HabitTrackingType _customTrackingType = HabitTrackingType.checkIn;
  double _customDailyTarget = 1;
  String _customTargetUnit = '';
  String _customTrigger = '';
  String _customCopingPlan = '';
  Set<int> _customActiveDays = const {1, 2, 3, 4, 5, 6, 7};

  static const int _totalSteps = 11;

  void _advance() {
    setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final showNav = _currentStep > 0 && _currentStep < _totalSteps - 1;

    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      body: SafeArea(
        child: Column(children: [
          if (showNav) _navBar(),
          Expanded(child: _screenContent()),
        ]),
      ),
    );
  }

  Widget _navBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(children: [
        if (_currentStep > 1)
          GestureDetector(
            onTap: _back,
            child: SizedBox(
              width: 44, height: 44,
              child: Icon(Icons.chevron_left, color: TributeColor.softGold.withValues(alpha: 0.6)),
            ),
          )
        else
          const SizedBox(width: 44),
        const Spacer(),
        _progressDots(),
        const Spacer(),
        const SizedBox(width: 44),
      ]),
    );
  }

  Widget _progressDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalSteps - 2, (i) {
        final step = i + 1;
        final active = step == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 8 : 6,
          height: active ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step <= _currentStep
                ? TributeColor.golden
                : Colors.white.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }

  Widget _screenContent() {
    switch (_currentStep) {
      case 0:
        return WelcomeScreen(onNext: _advance);

      case 1:
        return IdentityScreen(
          onContinue: (selections) {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setStringList('tribute_identity_selections', selections);
            });
            _advance();
          },
          onSkip: _advance,
        );

      case 2:
        return ReframeScreen(onNext: _advance);

      case 3:
        return FirstGratitudeScreen(
          onComplete: (note) {
            _gratitudeNote = note;
            _createGratitudeHabit(note);
            _advance();
          },
        );

      case 4:
        return HabitSelectionScreen(
          onSelect: (category) {
            setState(() => _selectedCategory = category);
            _advance();
          },
        );

      case 5:
        if (_selectedCategory == null) {
          _advance();
          return const SizedBox.shrink();
        }
        return HabitSetupScreen(
          category: _selectedCategory!,
          onComplete: (name, purpose, tracking, target, unit, trigger, copingPlan, days) {
            setState(() {
              _customHabitName = name;
              _customPurpose = purpose;
              _customTrackingType = tracking;
              _customDailyTarget = target;
              _customTargetUnit = unit;
              _customTrigger = trigger;
              _customCopingPlan = copingPlan;
              _customActiveDays = days;
            });
            _advance();
          },
        );

      case 6:
        if (_selectedCategory == null) {
          _advance();
          return const SizedBox.shrink();
        }
        return HabitSummaryScreen(
          habitName: _customHabitName,
          habitCategory: _selectedCategory!,
          trackingType: _customTrackingType,
          purposeStatement: _customPurpose,
          dailyTarget: _customDailyTarget,
          targetUnit: _customTargetUnit,
          activeDays: _customActiveDays,
          onFinish: () {
            _createCustomHabit();
            _advance();
          },
        );

      case 7:
        return CoreMechanicsScreen(onNext: _advance);

      case 8:
        return NotificationPreferencesScreen(onNext: _advance);

      case 9:
        return PaywallScreen(onNext: _advance);

      case 10:
        return DedicationCeremonyScreen(
          gratitudeNote: _gratitudeNote,
          habitName: _customHabitName,
          habitCategory: _selectedCategory ?? HabitCategory.gratitude,
          purposeStatement: _customPurpose,
          trackingType: _customTrackingType,
          dailyTarget: _customDailyTarget,
          targetUnit: _customTargetUnit,
          onComplete: widget.onComplete,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _createGratitudeHabit(String? note) {
    final provider = context.read<HabitProvider>();
    final hasGratitude = provider.habits.any(
        (h) => h.isBuiltIn && h.habitCategory == HabitCategory.gratitude);
    if (hasGratitude) return;
    provider.addHabit(
      name: 'Daily Gratitude',
      category: HabitCategory.gratitude,
      trackingType: HabitTrackingType.checkIn,
      purpose: 'Give thanks in all circumstances; for this is God\u2019s will for you in Christ Jesus.',
      dailyTarget: 1,
      targetUnit: '',
    ).then((_) {
      if (note != null && provider.habits.isNotEmpty) {
        final gratitude = provider.habits.firstWhere(
            (h) => h.isBuiltIn && h.habitCategory == HabitCategory.gratitude,
            orElse: () => provider.habits.first);
        provider.checkInGratitude(gratitude, note: note, date: DateTime.now());
      }
    });
  }

  void _createCustomHabit() {
    if (_selectedCategory == null || _customHabitName.isEmpty) return;
    context.read<HabitProvider>().addHabit(
      name: _customHabitName,
      category: _selectedCategory!,
      trackingType: _customTrackingType,
      purpose: _customPurpose,
      dailyTarget: _customDailyTarget,
      targetUnit: _customTargetUnit,
      activeDays: _customActiveDays,
      trigger: _customTrigger,
      copingPlan: _customCopingPlan,
    );
  }
}
