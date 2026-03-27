import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/week_cycle_manager.dart';
import 'today/today_view.dart';
import 'week/week_view.dart';
import 'journey/journey_view.dart';
import 'circles/circles_tab.dart';
import 'settings/settings_view.dart';
import 'shared/week_look_back_view.dart';
import 'shared/sunday_dedication_view.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> with WidgetsBindingObserver {
  int _selectedTab = 0;
  bool _showingLookBack = false;
  bool _showingDedication = false;
  bool _showAutoCarryBanner = false;
  bool _hasNewGratitudes = false;
  bool _checkingGratitudes = false;
  String? _pendingInviteCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAppear());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNewGratitudes();
    }
  }

  Future<void> _onAppear() async {
    await _checkWeekCycleState();
    _checkNewGratitudes();
  }

  Future<void> _checkWeekCycleState() async {
    final wcm = context.read<WeekCycleManager>();
    final habits = context.read<HabitProvider>().habits;
    final needsLookBack = await wcm.needsLookBack;
    final needsDedication = await wcm.needsDedication;

    if (!mounted) return;

    if (needsLookBack && habits.isNotEmpty) {
      setState(() => _showingLookBack = true);
    } else if (needsDedication) {
      if (habits.isEmpty) {
        setState(() => _showAutoCarryBanner = false);
      } else {
        final dedicated = await wcm.weekDedicatedDate;
        if (!mounted) return;
        setState(() {
          if (dedicated != null) _showAutoCarryBanner = true;
          _showingDedication = true;
        });
      }
    }
  }

  Future<void> _checkNewGratitudes() async {
    final isAuthenticated = context.read<AuthService>().isAuthenticated;
    if (!isAuthenticated) return;
    // Prevent stacked concurrent calls (e.g. rapid background/foreground).
    if (_checkingGratitudes) return;
    _checkingGratitudes = true;
    try {
      final circleRepo = context.read<CircleRepository>();
      final circles = await circleRepo.listCircles();
      // Fetch all counts in parallel instead of sequentially.
      final counts = await Future.wait(
        circles.map((c) => circleRepo.getGratitudeNewCount(c.id)),
      );
      final hasNew = counts.any((n) => n > 0);
      if (mounted) setState(() => _hasNewGratitudes = hasNew);
    } catch (_) {
      // Network failure — leave badge state unchanged.
    } finally {
      _checkingGratitudes = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wcm = context.read<WeekCycleManager>();
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedTab,
            children: [
              TodayView(
                weekCycleManager: wcm,
                showAutoCarryBanner: _showAutoCarryBanner,
                onDismissAutoCarry: () => setState(() => _showAutoCarryBanner = false),
              ),
              WeekView(weekCycleManager: wcm),
              const JourneyView(),
              CirclesTab(
                pendingInviteCode: _pendingInviteCode,
                onInviteCodeConsumed: () =>
                    setState(() => _pendingInviteCode = null),
              ),
              const SettingsView(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (i) {
              setState(() {
                _selectedTab = i;
                if (i == 3) _hasNewGratitudes = false;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard),
                label: 'Give',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Week',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Journey',
              ),
              BottomNavigationBarItem(
                icon: _hasNewGratitudes
                    ? Badge(child: const Icon(Icons.groups))
                    : const Icon(Icons.groups),
                label: 'Circles',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
        if (_showingLookBack)
          WeekLookBackView(
            weekCycleManager: wcm,
            onDismiss: () async {
              await wcm.completeLookBack();
              final needsDedication = await wcm.needsDedication;
              if (mounted) {
                setState(() {
                  _showingLookBack = false;
                  _showingDedication = needsDedication;
                });
              }
            },
          ),
        if (_showingDedication)
          SundayDedicationView(
            weekCycleManager: wcm,
            onDismiss: () => setState(() => _showingDedication = false),
          ),
      ],
    );
  }
}
