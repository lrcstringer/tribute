import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/store_provider.dart';
import '../../providers/prayer_list_provider.dart';
import '../../providers/scripture_focus_provider.dart';
import '../../providers/circle_habits_provider.dart';
import '../../providers/encouragement_provider.dart';
import '../../providers/milestone_share_provider.dart';
import '../../providers/circle_habit_milestone_provider.dart';
import '../../providers/weekly_pulse_provider.dart';
import '../../providers/circle_events_provider.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import 'circle_sunday_summary_view.dart';
import 'gratitude_wall_view.dart' show GratitudeWallWidget;
import 'sos_prayer_request_view.dart';
import '../shared/mywalk_paywall_view.dart';
import 'prayer_list_tab.dart';
import 'scripture_focus_tab.dart';
import 'circle_habits_tab.dart';
import 'activity_tab.dart';
import 'events_tab.dart';
import 'circle_settings_view.dart';

class CircleDetailView extends StatefulWidget {
  final String circleId;
  const CircleDetailView({super.key, required this.circleId});

  @override
  State<CircleDetailView> createState() => _CircleDetailViewState();
}

class _CircleDetailViewState extends State<CircleDetailView>
    with SingleTickerProviderStateMixin {
  CircleDetails? _detail;
  bool _isLoading = true;
  String? _error;
  bool _isLeaving = false;
  CircleHeatmap? _heatmap;
  bool _heatmapFailed = false;
  CollectiveMilestones? _milestones;
  bool _milestonesFailed = false;

  late final TabController _tabController;

  static final _tabs = [
    ('Overview', Icons.home_rounded),
    ('Prayer', Icons.volunteer_activism_rounded),
    ('Scripture', Icons.menu_book_rounded),
    ('Habits', Icons.check_circle_outline_rounded),
    ('Activity', Icons.people_rounded),
    ('Events', Icons.event_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadDetail();
    _loadHeatmap();
    _loadMilestones();
    _loadProviders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProviders() {
    final uid = AuthService.shared.userId ?? '';
    context.read<PrayerListProvider>().load(widget.circleId);
    context.read<ScriptureFocusProvider>().load(widget.circleId, uid);
    context.read<CircleHabitsProvider>().load(widget.circleId);
    context.read<EncouragementProvider>().load(widget.circleId);
    context.read<MilestoneShareProvider>().load(widget.circleId);
    context.read<CircleHabitMilestoneProvider>().load(widget.circleId);
    context.read<WeeklyPulseProvider>().load(widget.circleId, uid);
    context.read<CircleEventsProvider>().load(widget.circleId);
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final detail = await context.read<CircleRepository>().getCircleDetail(widget.circleId);
      if (mounted) setState(() { _detail = detail; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadHeatmap() async {
    final isPremium = context.read<StoreProvider>().isPremium;
    try {
      final heatmap = await context.read<CircleRepository>().getCircleHeatmap(
        widget.circleId, weekCount: isPremium ? 52 : 1);
      if (mounted) setState(() => _heatmap = heatmap);
    } catch (_) {
      if (mounted) setState(() => _heatmapFailed = true);
    }
  }

  Future<void> _loadMilestones() async {
    try {
      final milestones = await context.read<CircleRepository>().getCircleMilestones(widget.circleId);
      if (mounted) setState(() => _milestones = milestones);
    } catch (_) {
      if (mounted) setState(() => _milestonesFailed = true);
    }
  }

  Future<void> _leaveCircle() async {
    setState(() => _isLeaving = true);
    try {
      await context.read<CircleRepository>().leaveCircle(widget.circleId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLeaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: MyWalkColor.golden));
    }
    if (_detail == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.warning_amber_rounded, size: 32, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(_error ?? 'Failed to load', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadDetail,
              child: const Text('Retry', style: TextStyle(color: MyWalkColor.golden))),
        ]),
      );
    }
    return _buildTabView(_detail!);
  }

  Widget _buildTabView(CircleDetails detail) {
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          backgroundColor: MyWalkColor.charcoal,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(detail.name,
                style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${detail.memberCount} members',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ]),
          actions: [
            if (detail.members.any((m) => m.userId == AuthService.shared.userId && m.isAdmin))
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 20, color: MyWalkColor.softGold),
                onPressed: () => _openSettings(detail),
              ),
            IconButton(
              icon: const Icon(Icons.link_rounded, size: 20, color: MyWalkColor.golden),
              onPressed: () => _shareInvite(detail),
            ),
          ],
          floating: true,
          snap: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: MyWalkColor.golden,
            unselectedLabelColor: MyWalkColor.softGold,
            indicatorColor: MyWalkColor.golden,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: _tabs.map((t) => Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.$2, size: 14),
                const SizedBox(width: 5),
                Text(t.$1),
              ]),
            )).toList(),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            circleId: widget.circleId,
            detail: detail,
            heatmap: _heatmap,
            heatmapFailed: _heatmapFailed,
            milestones: _milestones,
            milestonesFailed: _milestonesFailed,
            onSOSTap: () => _showSOSRequest(detail),
            onSummaryTap: () => _showSundaySummary(detail),
            onLeaveTap: _confirmLeave,
            isLeaving: _isLeaving,
            onRoleChanged: _loadDetail,
          ),
          PrayerListTab(circleId: widget.circleId),
          ScriptureFocusTab(circleId: widget.circleId, settings: detail.settings),
          CircleHabitsTab(circleId: widget.circleId, isAdmin: detail.members.any(
              (m) => m.userId == AuthService.shared.userId && m.isAdmin)),
          ActivityTab(circleId: widget.circleId, members: detail.members),
          EventsTab(circleId: widget.circleId, isAdmin: detail.members.any(
              (m) => m.userId == AuthService.shared.userId && m.isAdmin)),
        ],
      ),
    );
  }

  void _showSOSRequest(CircleDetails detail) {
    final isPremium = context.read<StoreProvider>().isPremium;
    if (!isPremium) {
      showModalBottomSheet(
        context: context, isScrollControlled: true, useSafeArea: true,
        backgroundColor: MyWalkColor.charcoal,
        builder: (_) => const MyWalkPaywallView(
          contextTitle: 'SOS Support',
          contextMessage: "Tough moment? The SOS feature can help — it'll remind you why you started and connect you with your circle.",
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => SOSPrayerRequestView(circleId: widget.circleId, members: detail.members),
    );
  }

  void _showSundaySummary(CircleDetails detail) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => CircleSundaySummaryView(circleId: widget.circleId, circleName: detail.name),
    );
  }

  void _shareInvite(CircleDetails detail) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => _ShareInviteSheet(
        circleName: detail.name, inviteCode: detail.inviteCode),
    );
  }

  void _openSettings(CircleDetails detail) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CircleSettingsView(circleId: widget.circleId, settings: detail.settings),
    ));
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Leave Circle', style: TextStyle(color: MyWalkColor.warmWhite)),
        content: Text(
          "You'll no longer receive prayer requests or see this circle's progress.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _leaveCircle(); },
            child: const Text('Leave', style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String circleId;
  final CircleDetails detail;
  final CircleHeatmap? heatmap;
  final bool heatmapFailed;
  final CollectiveMilestones? milestones;
  final bool milestonesFailed;
  final VoidCallback onSOSTap;
  final VoidCallback onSummaryTap;
  final VoidCallback onLeaveTap;
  final bool isLeaving;
  final VoidCallback onRoleChanged;

  const _OverviewTab({
    required this.circleId,
    required this.detail,
    required this.heatmap,
    required this.heatmapFailed,
    required this.milestones,
    required this.milestonesFailed,
    required this.onSOSTap,
    required this.onSummaryTap,
    required this.onLeaveTap,
    required this.isLeaving,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _collaborativeHeatmapSection(isPremium),
        const SizedBox(height: 16),
        _collectiveMilestonesSection(),
        const SizedBox(height: 16),
        GratitudeWallWidget(circleId: circleId),
        const SizedBox(height: 16),
        _sectionHeader('Actions'),
        const SizedBox(height: 8),
        _actionRow(
          icon: Icons.bolt_rounded, iconColor: MyWalkColor.warmCoral,
          iconBg: MyWalkColor.warmCoral.withValues(alpha: 0.12),
          title: 'SOS Prayer Request', subtitle: 'Ask your circle to pray for you now',
          onTap: onSOSTap,
        ),
        const SizedBox(height: 8),
        _actionRow(
          icon: Icons.wb_sunny_rounded, iconColor: MyWalkColor.golden,
          iconBg: MyWalkColor.golden.withValues(alpha: 0.12),
          title: 'Weekly Summary', subtitle: "See your circle's faithfulness this week",
          onTap: onSummaryTap,
        ),
        const SizedBox(height: 16),
        _sectionHeader('Members (${detail.members.length})'),
        const SizedBox(height: 8),
        ...detail.members.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _memberRow(context, m),
        )),
        const SizedBox(height: 16),
        _leaveButton(),
      ],
    );
  }

  Widget _collaborativeHeatmapSection(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.grid_view_rounded, size: 13, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          Text('Circle Activity',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
          const Spacer(),
          Text('${detail.memberCount} members',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        ]),
        const SizedBox(height: 6),
        Text(
          'When members have a strong day, this glows. The more the circle gives, the brighter it gets.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45), height: 1.4),
        ),
        const SizedBox(height: 12),
        if (heatmapFailed)
          Text('Could not load activity data.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))
        else if (heatmap == null)
          const SizedBox(height: 32,
            child: Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: MyWalkColor.golden))))
        else
          _CircleHeatmapGrid(heatmap: heatmap!, isPremium: isPremium),
        if (!isPremium) ...[
          const SizedBox(height: 8),
          Text('Upgrade to see your full 52-week circle history.',
              style: TextStyle(fontSize: 11, color: MyWalkColor.golden.withValues(alpha: 0.5))),
        ],
      ]),
    );
  }

  Widget _collectiveMilestonesSection() {
    final ms = milestones;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star_rounded, size: 13, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          Text('Circle Milestones',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
        ]),
        const SizedBox(height: 10),
        if (milestonesFailed)
          Text('Could not load milestones.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))
        else if (ms == null)
          const SizedBox(height: 32,
            child: Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: MyWalkColor.golden))))
        else ...[
          if (ms.totalGivingDays > 0 || ms.totalHours > 0 || ms.totalGratitudeDays > 0)
            _milestoneTotalsRow(ms),
          const SizedBox(height: 10),
          if (ms.milestones.isEmpty)
            Text('Keep going — your first circle milestone is on its way.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), height: 1.4))
          else
            ...ms.milestones.take(3).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _milestoneTile(m),
            )),
        ],
      ]),
    );
  }

  Widget _milestoneTotalsRow(CollectiveMilestones ms) {
    final items = <_TotalItem>[];
    if (ms.totalGivingDays > 0) items.add(_TotalItem('${ms.totalGivingDays}', 'giving days'));
    if (ms.totalHours >= 1) {
      final h = ms.totalHours.floor();
      items.add(_TotalItem('$h', h == 1 ? 'hour' : 'hours'));
    }
    if (ms.totalGratitudeDays > 0) items.add(_TotalItem('${ms.totalGratitudeDays}', 'gratitude days'));
    return Row(
      children: items.map((item) => Expanded(
        child: Column(children: [
          Text(item.value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
          Text(item.label,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
        ]),
      )).toList(),
    );
  }

  Widget _milestoneTile(CollectiveMilestone m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.star_rounded, size: 16, color: MyWalkColor.golden),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 2),
          Text(m.message,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2));
  }

  Widget _actionRow({
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.12), width: 0.5),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
          ])),
          Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  Widget _memberRow(BuildContext context, CircleMember m) {
    final currentUid = AuthService.shared.userId ?? '';
    final currentUserIsAdmin = detail.members.any((x) => x.userId == currentUid && x.isAdmin);
    final isSelf = m.userId == currentUid;
    final isAdmin = m.isAdmin;
    final color = isAdmin ? MyWalkColor.golden : MyWalkColor.sage;
    return GestureDetector(
      onTap: currentUserIsAdmin && !isSelf ? () => _showRoleDialog(context, m) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: MyWalkDecorations.card,
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
            child: Icon(Icons.person_rounded, size: 14, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isSelf ? 'You' : m.displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite)),
            Text(isAdmin ? 'Admin' : 'Member',
                style: TextStyle(fontSize: 11,
                    color: isAdmin ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.4))),
          ])),
          if (currentUserIsAdmin && !isSelf)
            Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white.withValues(alpha: 0.25)),
        ]),
      ),
    );
  }

  void _showRoleDialog(BuildContext context, CircleMember m) {
    final isAdmin = m.isAdmin;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: Text(isAdmin ? 'Remove Admin' : 'Make Admin',
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text(
          isAdmin
              ? 'Remove admin privileges from this member? They will become a regular member.'
              : 'Give this member admin privileges? They will be able to manage habits, events, and circle settings.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CircleRepository>().updateMemberRole(
                circleId, m.userId, isAdmin ? 'member' : 'admin',
              ).then((_) => onRoleChanged());
            },
            child: Text(isAdmin ? 'Remove Admin' : 'Make Admin',
                style: const TextStyle(color: MyWalkColor.golden)),
          ),
        ],
      ),
    );
  }

  Widget _leaveButton() {
    return GestureDetector(
      onTap: isLeaving ? null : onLeaveTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.warmCoral.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.logout_rounded, size: 16, color: MyWalkColor.warmCoral),
          const SizedBox(width: 10),
          const Expanded(child: Text('Leave Circle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmCoral))),
          if (isLeaving)
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.warmCoral)),
        ]),
      ),
    );
  }
}

// ─── Share invite sheet ───────────────────────────────────────────────────────

class _ShareInviteSheet extends StatelessWidget {
  final String circleName;
  final String inviteCode;
  const _ShareInviteSheet({required this.circleName, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Invite', style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(width: 64, height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: MyWalkColor.golden.withValues(alpha: 0.1)),
              child: const Icon(Icons.link_rounded, size: 28, color: MyWalkColor.golden)),
            const SizedBox(height: 12),
            Text('Invite to $circleName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = 'Join my Prayer Circle "$circleName" on MyWalk!\n\n'
                    'Tap to join: https://mywalk.faith/join?code=$inviteCode\n\n'
                    'Or enter invite code "$inviteCode" manually in the app.';
                  Share.share(text);
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Invite', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: inviteCode)),
                icon: const Icon(Icons.copy_rounded, size: 16, color: MyWalkColor.golden),
                label: Text('Copy Code: $inviteCode',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.golden)),
                style: TextButton.styleFrom(
                  backgroundColor: MyWalkColor.golden.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Supporting types ─────────────────────────────────────────────────────────

class _TotalItem {
  final String value;
  final String label;
  const _TotalItem(this.value, this.label);
}

// ─── Collaborative heatmap grid ───────────────────────────────────────────────

class _CircleHeatmapGrid extends StatelessWidget {
  final CircleHeatmap heatmap;
  final bool isPremium;

  const _CircleHeatmapGrid({required this.heatmap, required this.isPremium});

  static const _tileSize = 10.0;
  static const _gap = 2.0;
  static const _stride = _tileSize + _gap;
  static const _dayLabelWidth = 14.0;
  static const _monthRowHeight = 13.0;
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthAbbrs = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Map<String, double> _intensityMap() => {for (final d in heatmap.days) d.date: d.intensity};

  List<List<DateTime>> _buildWeeks() {
    final weekCount = isPremium ? 52 : 1;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));
    return List.generate(weekCount, (i) {
      final weekStart = currentWeekStart.add(Duration(days: (i - (weekCount - 1)) * 7));
      return List.generate(7, (d) => weekStart.add(Duration(days: d)));
    });
  }

  Color _cellColor(double intensity) {
    if (intensity <= 0.0) return MyWalkColor.surfaceOverlay;
    if (intensity <= 0.25) return MyWalkColor.golden.withValues(alpha: 0.15);
    if (intensity <= 0.65) return MyWalkColor.golden.withValues(alpha: 0.50);
    return MyWalkColor.golden.withValues(alpha: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final map = _intensityMap();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    if (weeks.length == 1) {
      return Row(
        children: weeks.first.map((date) {
          final isFuture = date.isAfter(todayStart);
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final intensity = isFuture ? 0.0 : (map[key] ?? 0.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFuture ? Colors.white.withValues(alpha: 0.02) : _cellColor(intensity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _monthRowHeight + 1),
          child: Column(
            children: List.generate(7, (i) => SizedBox(
              width: _dayLabelWidth, height: _stride,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_dayLabels[i],
                    style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.35))),
              ),
            )),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _monthRowHeight,
                  child: Row(
                    children: List.generate(weeks.length, (i) {
                      final sunday = weeks[i].first;
                      final showMonth = i == 0 || sunday.month != weeks[i - 1].first.month;
                      return SizedBox(
                        width: _stride,
                        child: showMonth
                            ? Text(_monthAbbrs[sunday.month - 1],
                                style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.4)))
                            : null,
                      );
                    }),
                  ),
                ),
                ...List.generate(7, (dayIndex) => Row(
                  children: weeks.map((week) {
                    final date = week[dayIndex];
                    final isFuture = date.isAfter(todayStart);
                    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final intensity = isFuture ? 0.0 : (map[key] ?? 0.0);
                    return Padding(
                      padding: const EdgeInsets.only(right: _gap, bottom: _gap),
                      child: Container(
                        width: _tileSize, height: _tileSize,
                        decoration: BoxDecoration(
                          color: isFuture ? Colors.white.withValues(alpha: 0.02) : _cellColor(intensity),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: !isFuture && intensity > 0.65
                              ? [BoxShadow(color: MyWalkColor.golden.withValues(alpha: 0.35), blurRadius: 3)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
