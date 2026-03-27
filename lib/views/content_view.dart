import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/week_cycle_manager.dart';
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
  String? _pendingInviteCode;

  final _weekCycleManager = WeekCycleManager();

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
    final habits = context.read<HabitProvider>().habits;
    final needsLookBack = await _weekCycleManager.needsLookBack;
    final needsDedication = await _weekCycleManager.needsDedication;

    if (!mounted) return;

    if (needsLookBack && habits.isNotEmpty) {
      setState(() => _showingLookBack = true);
    } else if (needsDedication) {
      if (habits.isEmpty) {
        setState(() => _showAutoCarryBanner = false);
      } else {
        final dedicated = await _weekCycleManager.weekDedicatedDate;
        if (dedicated != null) setState(() => _showAutoCarryBanner = true);
        if (mounted) setState(() => _showingDedication = true);
      }
    }
  }

  Future<void> _checkNewGratitudes() async {
    if (!AuthService.shared.isAuthenticated) return;
    try {
      final circles = await APIService.shared.listCircles();
      for (final circle in circles) {
        final count = await APIService.shared.getGratitudeNewCount(circle.id);
        if (count.newCount > 0) {
          if (mounted) setState(() => _hasNewGratitudes = true);
          return;
        }
      }
      if (mounted) setState(() => _hasNewGratitudes = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedTab,
            children: [
              TodayView(
                weekCycleManager: _weekCycleManager,
                showAutoCarryBanner: _showAutoCarryBanner,
                onDismissAutoCarry: () => setState(() => _showAutoCarryBanner = false),
              ),
              WeekView(weekCycleManager: _weekCycleManager),
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
            weekCycleManager: _weekCycleManager,
            onDismiss: () async {
              await _weekCycleManager.completeLookBack();
              final needsDedication = await _weekCycleManager.needsDedication;
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
            weekCycleManager: _weekCycleManager,
            onDismiss: () => setState(() => _showingDedication = false),
          ),
      ],
    );
  }
}
