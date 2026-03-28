import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart';
import 'sign_in_screen.dart';
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
  bool _isSavingHabit = false;
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

  // 0: Welcome  1: SignIn  2: Identity  3: Reframe  4: FirstGratitude
  // 5: HabitSelection  6: HabitSetup  7: HabitSummary  8: CoreMechanics
  // 9: NotificationPrefs  10: Paywall  11: DedicationCeremony
  static const int _totalSteps = 12;

  void _advance() => setState(() => _currentStep++);

  void _back() {
    if (_currentStep > 2) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    // Show nav bar for steps 2-10 (between sign-in and dedication).
    final showNav = _currentStep >= 2 && _currentStep < _totalSteps - 1;

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
        if (_currentStep > 2)
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
    // Dots for steps 2-10 (9 dots total).
    const dotSteps = _totalSteps - 3; // steps 2..10 = 9
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotSteps, (i) {
        final step = i + 2;
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
        return SignInScreen(onNext: _advance);

      case 2:
        final auth = context.read<AuthService>();
        return IdentityScreen(
          prefilledName: auth.givenName,
          onContinue: (name, selections) => _onIdentityContinue(name, selections),
          onSkip: _advance,
        );

      case 3:
        return ReframeScreen(onNext: _advance);

      case 4:
        return FirstGratitudeScreen(
          onComplete: (note) {
            _gratitudeNote = note;
            _createGratitudeHabit(note);
            _advance();
          },
        );

      case 5:
        return HabitSelectionScreen(
          onSelect: (category) {
            setState(() => _selectedCategory = category);
            _advance();
          },
        );

      case 6:
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

      case 7:
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
          onFinish: () => _createCustomHabitAndAdvance(),
        );

      case 8:
        return CoreMechanicsScreen(
          onNext: _advance,
          givenName: context.read<AuthService>().givenName,
        );

      case 9:
        return NotificationPreferencesScreen(onNext: _advance);

      case 10:
        return PaywallScreen(onNext: _advance);

      case 11:
        return DedicationCeremonyScreen(
          gratitudeNote: _gratitudeNote,
          habitName: _customHabitName,
          habitCategory: _selectedCategory ?? HabitCategory.gratitude,
          purposeStatement: _customPurpose,
          trackingType: _customTrackingType,
          dailyTarget: _customDailyTarget,
          targetUnit: _customTargetUnit,
          onComplete: widget.onComplete,
          givenName: context.read<AuthService>().givenName,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  Future<void> _onIdentityContinue(String name, List<String> selections) async {
    // Persist name + identity selections to Firestore.
    final auth = context.read<AuthService>();
    if (auth.userId != null) {
      final repo = context.read<UserRepository>();
      await repo.updateFields({
        'name': name.isNotEmpty ? name : null,
        'identitySelections': selections,
      });
    }
    _advance();
  }

  void _createGratitudeHabit(String? note) {
    final provider = context.read<HabitProvider>();
    final hasGratitude = provider.habits.any(
        (h) => h.category == HabitCategory.gratitude);
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
            (h) => h.isBuiltIn && h.category == HabitCategory.gratitude,
            orElse: () => provider.habits.first);
        provider.checkInGratitude(gratitude, note: note, date: DateTime.now());
      }
    });
  }

  Future<void> _createCustomHabitAndAdvance() async {
    if (_isSavingHabit) return;
    if (_selectedCategory == null || _customHabitName.isEmpty) {
      _advance();
      return;
    }
    setState(() => _isSavingHabit = true);
    try {
      await context.read<HabitProvider>().addHabit(
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
      if (mounted) _advance();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save your habit. Check your connection and try again."),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingHabit = false);
    }
  }
}
