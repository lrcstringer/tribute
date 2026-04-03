import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/pending_invite_service.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/week_cycle_manager.dart';
import 'circles/circle_invitation_dialog.dart';
import 'today/today_view.dart';
import 'progress/progress_view.dart';
import 'fruit/fruit_portfolio_view.dart';
import 'circles/circles_tab.dart';
import 'journal/journal_tab.dart';
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
  bool _prevAuthenticated = false;
  StreamSubscription<String>? _inviteSub;

  @override
  void initState() {
    super.initState();
    _prevAuthenticated = AuthService.shared.isAuthenticated;
    AuthService.shared.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onAppear();
      _consumePendingInvite();
    });
    // Listen for deep links that arrive while the app is already running.
    _inviteSub = context
        .read<PendingInviteService>()
        .stream
        .listen((code) => _showInviteDialog(code));
  }

  @override
  void dispose() {
    AuthService.shared.removeListener(_onAuthChanged);
    _inviteSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAuthChanged() {
    final isNowAuthenticated = AuthService.shared.isAuthenticated;
    if (_prevAuthenticated && !isNowAuthenticated && mounted) {
      setState(() => _selectedTab = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been signed out.')),
      );
    }
    _prevAuthenticated = isNowAuthenticated;
  }

  /// Picks up any invite code that was saved before ContentView was mounted
  /// (e.g. the app was cold-started via a deep link during onboarding).
  void _consumePendingInvite() {
    final code = context.read<PendingInviteService>().consume();
    if (code != null) _showInviteDialog(code);
  }

  Future<void> _showInviteDialog(String code) async {
    if (!mounted) return;
    await CircleInvitationDialog.show(context, code);
    // Refresh gratitude badge in case the user just joined a new circle.
    if (mounted) _checkNewGratitudes();
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
    } else if (needsDedication && habits.isNotEmpty) {
      final dedicated = await wcm.weekDedicatedDate;
      if (!mounted) return;
      // Auto-carry: user had a previous dedication but missed Sunday —
      // silently dedicate and show a one-tap banner instead of the full ceremony.
      if (dedicated != null && !wcm.isSunday) {
        await wcm.dedicateCurrentWeek();
        if (mounted) setState(() => _showAutoCarryBanner = true);
      } else {
        // Sunday, or first-time user — show full dedication ceremony.
        setState(() => _showingDedication = true);
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
              ProgressView(weekCycleManager: wcm),
              const JournalTab(),
              const FruitPortfolioView(),
              const CirclesTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (i) {
              setState(() {
                _selectedTab = i;
                if (i == 4) _hasNewGratitudes = false;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard),
                label: 'Today',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Progress',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Journal',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.eco_outlined),
                activeIcon: Icon(Icons.eco),
                label: 'Fruit',
              ),
              BottomNavigationBarItem(
                icon: _hasNewGratitudes
                    ? Badge(child: const Icon(Icons.groups))
                    : const Icon(Icons.groups),
                label: 'Circles',
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
