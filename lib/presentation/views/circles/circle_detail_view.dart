import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/store_provider.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';
import 'circle_sunday_summary_view.dart';
import 'gratitude_wall_view.dart' show GratitudeWallWidget;
import 'sos_prayer_request_view.dart';
import '../shared/tribute_paywall_view.dart';

class CircleDetailView extends StatefulWidget {
  final String circleId;
  const CircleDetailView({super.key, required this.circleId});

  @override
  State<CircleDetailView> createState() => _CircleDetailViewState();
}

class _CircleDetailViewState extends State<CircleDetailView> {
  CircleDetails? _detail;
  bool _isLoading = true;
  String? _error;
  bool _isLeaving = false;
  List<SOSMessage> _recentSOS = [];
  CircleHeatmap? _heatmap;
  bool _heatmapFailed = false;
  CollectiveMilestones? _milestones;
  bool _milestonesFailed = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadRecentSOS();
    _loadHeatmap();
    _loadMilestones();
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

  Future<void> _loadRecentSOS() async {
    try {
      final sos = await context.read<CircleRepository>().getRecentSOS(circleId: widget.circleId, limit: 5);
      if (mounted) setState(() => _recentSOS = sos);
    } catch (_) {}
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

  String _relativeTime(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: TributeColor.golden));
    }
    if (_detail == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.warning_amber_rounded, size: 32, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(_error ?? 'Failed to load', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadDetail,
            child: const Text('Retry', style: TextStyle(color: TributeColor.golden)),
          ),
        ]),
      );
    }
    return _circleContent(_detail!);
  }

  Widget _circleContent(CircleDetails detail) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: TributeColor.charcoal,
          title: Text(detail.name,
              style: const TextStyle(color: TributeColor.warmWhite, fontSize: 20, fontWeight: FontWeight.w700)),
          floating: true, snap: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (detail.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(detail.description, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.group, size: 13, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('${detail.memberCount} members',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
              ]),
              const SizedBox(height: 20),
              // Collaborative heatmap
              _collaborativeHeatmapSection(detail),
              const SizedBox(height: 20),
              // Collective milestones
              _collectiveMilestonesSection(detail),
              const SizedBox(height: 20),
              // Gratitude Wall
              GratitudeWallWidget(circleId: widget.circleId),
              const SizedBox(height: 20),
              // Actions section
              _sectionHeader('Actions'),
              const SizedBox(height: 8),
              _actionRow(
                icon: Icons.bolt_rounded, iconColor: TributeColor.warmCoral,
                iconBg: TributeColor.warmCoral.withValues(alpha: 0.12),
                title: 'SOS Prayer Request', subtitle: 'Ask up to 20 people to pray for you',
                onTap: () => _showSOSRequest(detail),
              ),
              const SizedBox(height: 8),
              _actionRow(
                icon: Icons.wb_sunny_rounded, iconColor: TributeColor.golden,
                iconBg: TributeColor.golden.withValues(alpha: 0.12),
                title: 'Weekly Summary', subtitle: "See your circle's faithfulness this week",
                onTap: () => _showSundaySummary(detail),
              ),
              if (_recentSOS.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader('Recent Prayer Requests'),
                const SizedBox(height: 8),
                ..._recentSOS.take(5).map((sos) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _sosItem(sos),
                    )),
              ],
              const SizedBox(height: 20),
              _sectionHeader('Invite'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: TributeDecorations.card,
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Invite Code',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                        Text(detail.inviteCode,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                color: TributeColor.golden, fontFamily: 'monospace')),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => Clipboard.setData(ClipboardData(text: detail.inviteCode)),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TributeColor.golden.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy_rounded, size: 18, color: TributeColor.golden),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _shareInvite(detail),
                    child: Row(children: [
                      const Icon(Icons.share_rounded, size: 14, color: TributeColor.golden),
                      const SizedBox(width: 8),
                      Text('Share Invite Link',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TributeColor.golden)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Members (${detail.members.length})'),
              const SizedBox(height: 8),
              ...detail.members.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _memberRow(m),
                  )),
              const SizedBox(height: 20),
              _leaveButton(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.warning_amber, size: 14, color: TributeColor.warmCoral),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: TributeColor.warmCoral))),
                ]),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _collaborativeHeatmapSection(CircleDetails detail) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    final heatmap = _heatmap;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TributeDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.grid_view_rounded, size: 13, color: TributeColor.golden),
          const SizedBox(width: 6),
          Text('Circle Activity',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.softGold)),
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
        if (_heatmapFailed)
          Text('Could not load activity data.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))
        else if (heatmap == null)
          SizedBox(
            height: 32,
            child: Center(child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5,
                    color: TributeColor.golden.withValues(alpha: 0.4)))),
          )
        else
          _CircleHeatmapGrid(heatmap: heatmap, isPremium: isPremium),
        if (!isPremium) ...[
          const SizedBox(height: 8),
          Text('Upgrade to see your full 52-week circle history.',
              style: TextStyle(fontSize: 11, color: TributeColor.golden.withValues(alpha: 0.5))),
        ],
      ]),
    );
  }

  Widget _collectiveMilestonesSection(CircleDetails detail) {
    final ms = _milestones;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TributeDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star_rounded, size: 13, color: TributeColor.golden),
          const SizedBox(width: 6),
          Text('Circle Milestones',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.softGold)),
        ]),
        const SizedBox(height: 10),
        if (_milestonesFailed)
          Text('Could not load milestones.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)))
        else if (ms == null)
          SizedBox(
            height: 32,
            child: Center(child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5,
                    color: TributeColor.golden.withValues(alpha: 0.4)))),
          )
        else ...[
          // Running totals
          if (ms.totalGivingDays > 0 || ms.totalHours > 0 || ms.totalGratitudeDays > 0)
            _milestoneTotalsRow(ms),
          const SizedBox(height: 10),
          // Milestone cards
          if (ms.milestones.isEmpty)
            Text(
              'Keep going — your first circle milestone is on its way.',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), height: 1.4),
            )
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: TributeColor.golden)),
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
        color: TributeColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TributeColor.golden.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.star_rounded, size: 16, color: TributeColor.golden),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
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
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
          ])),
          Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  Widget _sosItem(SOSMessage sos) {
    final isMine = sos.isMine;
    final color = isMine ? TributeColor.golden : TributeColor.warmCoral;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: TributeDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMine ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13, color: color),
          const SizedBox(width: 6),
          Text(isMine ? 'You requested prayer' : 'Prayer requested',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const Spacer(),
          Text(_relativeTime(sos.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(height: 6),
        Text(sos.message,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: TributeColor.warmWhite)),
      ]),
    );
  }

  Widget _memberRow(CircleMember m) {
    final isAdmin = m.role == 'admin';
    final color = isAdmin ? TributeColor.golden : TributeColor.sage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: TributeDecorations.card,
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
          child: Icon(Icons.person_rounded, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Member', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TributeColor.warmWhite)),
          if (isAdmin)
            const Text('Admin', style: TextStyle(fontSize: 11, color: TributeColor.golden)),
        ])),
      ]),
    );
  }

  Widget _leaveButton() {
    return GestureDetector(
      onTap: _isLeaving ? null : _confirmLeave,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TributeColor.warmCoral.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TributeColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.logout_rounded, size: 16, color: TributeColor.warmCoral),
          const SizedBox(width: 10),
          const Expanded(child: Text('Leave Circle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TributeColor.warmCoral))),
          if (_isLeaving)
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.warmCoral)),
        ]),
      ),
    );
  }

  void _showSOSRequest(CircleDetails detail) {
    final isPremium = context.read<StoreProvider>().isPremium;
    if (!isPremium && !kDebugMode) {
      showModalBottomSheet(
        context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: TributeColor.charcoal,
        builder: (_) => const TributePaywallView(
          contextTitle: 'SOS Support',
          contextMessage: 'Tough moment? The SOS feature can help — it\'ll remind you why you started and connect you with your circle.',
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: TributeColor.charcoal,
      builder: (_) => SOSPrayerRequestView(circleId: widget.circleId, members: detail.members),
    );
  }

  void _showSundaySummary(CircleDetails detail) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: TributeColor.charcoal,
      builder: (_) => CircleSundaySummaryView(circleId: widget.circleId, circleName: detail.name),
    );
  }

  void _shareInvite(CircleDetails detail) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: TributeColor.charcoal,
      builder: (_) => _ShareInviteSheet(
        circleName: detail.name, inviteCode: detail.inviteCode),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TributeColor.cardBackground,
        title: const Text('Leave Circle', style: TextStyle(color: TributeColor.warmWhite)),
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
            child: const Text('Leave', style: TextStyle(color: TributeColor.warmCoral)),
          ),
        ],
      ),
    );
  }
}

class _ShareInviteSheet extends StatelessWidget {
  final String circleName;
  final String inviteCode;
  const _ShareInviteSheet({required this.circleName, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      appBar: AppBar(
        backgroundColor: TributeColor.charcoal,
        title: const Text('Invite', style: TextStyle(color: TributeColor.warmWhite, fontSize: 17)),
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
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TributeColor.golden.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.link_rounded, size: 28, color: TributeColor.golden),
            ),
            const SizedBox(height: 12),
            Text('Invite to $circleName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: TributeColor.warmWhite)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = 'Join my Prayer Circle "$circleName" on Tribute!\n\nTap to join: https://tribute.app/join?code=$inviteCode\n\nOr enter invite code "$inviteCode" manually in the app.';
                  Share.share(text);
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Invite', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TributeColor.golden,
                  foregroundColor: TributeColor.charcoal,
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
                icon: const Icon(Icons.copy_rounded, size: 16, color: TributeColor.golden),
                label: Text('Copy Code: $inviteCode',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TributeColor.golden)),
                style: TextButton.styleFrom(
                  backgroundColor: TributeColor.golden.withValues(alpha: 0.1),
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

// ─── Supporting data class ────────────────────────────────────────────────────

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

  Map<String, double> _intensityMap() {
    return {for (final d in heatmap.days) d.date: d.intensity};
  }

  List<List<DateTime>> _buildWeeks() {
    final weekCount = isPremium ? 52 : 1;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));
    final result = <List<DateTime>>[];
    for (int w = -(weekCount - 1); w <= 0; w++) {
      final weekStart = currentWeekStart.add(Duration(days: w * 7));
      result.add(List.generate(7, (d) => weekStart.add(Duration(days: d))));
    }
    return result;
  }

  Color _cellColor(double intensity) {
    if (intensity <= 0.0) return TributeColor.surfaceOverlay;
    if (intensity <= 0.25) return TributeColor.golden.withValues(alpha: 0.15);
    if (intensity <= 0.65) return TributeColor.golden.withValues(alpha: 0.50);
    return TributeColor.golden.withValues(alpha: 0.85);
  }

  List<BoxShadow>? _cellGlow(double intensity) {
    if (intensity > 0.65) {
      return [BoxShadow(color: TributeColor.golden.withValues(alpha: 0.35), blurRadius: 3)];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final map = _intensityMap();
    final tileSpacing = isPremium ? 2.0 : 3.0;
    final cornerRadius = isPremium ? 2.0 : 3.0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((l) => Expanded(
          child: Text(l, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.35))),
        )).toList(),
      ),
      const SizedBox(height: 6),
      Column(
        children: weeks.map((week) => Padding(
          padding: EdgeInsets.only(bottom: tileSpacing),
          child: Row(
            children: week.map((date) {
              final isFuture = date.isAfter(todayStart);
              final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final intensity = isFuture ? 0.0 : (map[key] ?? 0.0);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tileSpacing / 2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFuture ? Colors.white.withValues(alpha: 0.02) : _cellColor(intensity),
                        borderRadius: BorderRadius.circular(cornerRadius),
                        boxShadow: isFuture ? null : _cellGlow(intensity),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )).toList(),
      ),
    ]);
  }
}
