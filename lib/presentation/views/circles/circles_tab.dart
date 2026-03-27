import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'circle_detail_view.dart';
import 'create_circle_view.dart';
import 'join_circle_view.dart';

class CirclesTab extends StatelessWidget {
  final String? pendingInviteCode;
  final VoidCallback? onInviteCodeConsumed;

  const CirclesTab({super.key, this.pendingInviteCode, this.onInviteCodeConsumed});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.isAuthenticated) {
      return _CirclesListView(
        pendingInviteCode: pendingInviteCode,
        onInviteCodeConsumed: onInviteCodeConsumed,
      );
    }
    return _CirclesAuthGateView(pendingInviteCode: pendingInviteCode);
  }
}

// ─── Auth gate ──────────────────────────────────────────────────────────────

class _CirclesAuthGateView extends StatelessWidget {
  final String? pendingInviteCode;
  const _CirclesAuthGateView({this.pendingInviteCode});

  static const _features = [
    (Icons.auto_awesome, 'SOS Prayers', 'Request urgent prayer from up to 20 people'),
    (Icons.bar_chart_rounded, 'Shared Progress', "See your circle's collective faithfulness"),
    (Icons.calendar_month, 'Sunday Summary', 'Weekly circle stats and encouragement'),
    (Icons.link, 'Easy Invites', 'Share a link to grow your circle'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Stack(alignment: Alignment.center, children: [
                Container(width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: TributeColor.golden.withValues(alpha: 0.08))),
                Container(width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: TributeColor.golden.withValues(alpha: 0.12))),
                const Icon(Icons.group_rounded, size: 32, color: TributeColor.golden),
              ]),
              const SizedBox(height: 20),
              const Text('Prayer Circles',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: TributeColor.warmWhite)),
              const SizedBox(height: 12),
              Text(
                'Walk together in faith with your community.\nCreate or join circles to share your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: TributeColor.softGold.withValues(alpha: 0.7), height: 1.6),
              ),
              const SizedBox(height: 32),
              ..._features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _featureRow(f.$1, f.$2, f.$3),
                  )),
              const SizedBox(height: 32),
              if (auth.error != null) ...[
                Text(auth.error!, style: const TextStyle(fontSize: 12, color: TributeColor.warmCoral)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: auth.isLoading ? null : auth.signInWithApple,
                  icon: auth.isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.charcoal))
                      : const Icon(Icons.apple, size: 20),
                  label: const Text('Sign in with Apple',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TributeColor.golden,
                    foregroundColor: TributeColor.charcoal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pendingInviteCode != null
                    ? 'Sign in to join this Prayer Circle'
                    : 'Sign in to create and join Prayer Circles',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TributeColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TributeColor.cardBorder, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: TributeColor.golden.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: TributeColor.golden),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
          Text(description, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ])),
      ]),
    );
  }
}

// ─── Circles list ────────────────────────────────────────────────────────────

class _CirclesListView extends StatefulWidget {
  final String? pendingInviteCode;
  final VoidCallback? onInviteCodeConsumed;
  const _CirclesListView({this.pendingInviteCode, this.onInviteCodeConsumed});

  @override
  State<_CirclesListView> createState() => _CirclesListViewState();
}

class _CirclesListViewState extends State<_CirclesListView> {
  List<CircleListItem> _circles = [];
  bool _isLoading = true;
  String? _error;
  String _joinCode = '';

  @override
  void initState() {
    super.initState();
    _loadCircles();
    final code = widget.pendingInviteCode;
    if (code != null && code.isNotEmpty) {
      _joinCode = code;
      widget.onInviteCodeConsumed?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) => _openJoin());
    }
  }

  Future<void> _loadCircles() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final circles = await APIService.shared.listCircles();
      if (mounted) setState(() => _circles = circles);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openJoin() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: TributeColor.charcoal,
    builder: (_) => JoinCircleView(
      initialCode: _joinCode,
      onJoined: () async { _joinCode = ''; await _loadCircles(); },
    ),
  );

  void _openCreate() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: TributeColor.charcoal,
    builder: (_) => CreateCircleView(
      onCreated: (c) => setState(() => _circles.insert(0, CircleListItem(
        id: c.id, name: c.name, description: '', memberCount: 1, role: 'admin', inviteCode: c.inviteCode,
      ))),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: TributeColor.charcoal,
              title: const Text('Circles',
                  style: TextStyle(color: TributeColor.warmWhite, fontSize: 22, fontWeight: FontWeight.w700)),
              floating: true, snap: true,
              actions: [
                if (_circles.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add, color: TributeColor.golden),
                    color: TributeColor.cardBackground,
                    onSelected: (v) => v == 'create' ? _openCreate() : _openJoin(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'create',
                          child: Text('Create Circle', style: TextStyle(color: TributeColor.warmWhite))),
                      PopupMenuItem(value: 'join',
                          child: Text('Join Circle', style: TextStyle(color: TributeColor.warmWhite))),
                    ],
                  ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: TributeColor.golden)))
            else if (_circles.isEmpty)
              SliverFillRemaining(child: _emptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final circle = _circles[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: TributeColor.golden.withValues(alpha: 0.1)),
                      child: Center(child: Text(
                        circle.name.isNotEmpty ? circle.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: TributeColor.golden),
                      )),
                    ),
                    title: Text(circle.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
                    subtitle: Row(children: [
                      Icon(Icons.group, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text('${circle.memberCount} members',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                    ]),
                    trailing: circle.role == 'admin'
                        ? Icon(Icons.workspace_premium, size: 14, color: TributeColor.golden.withValues(alpha: 0.5))
                        : null,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CircleDetailView(circleId: circle.id))),
                  );
                }, childCount: _circles.length),
              ),
            if (_error != null)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.warning_amber, size: 14, color: TributeColor.warmCoral),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(fontSize: 12, color: TributeColor.warmCoral))),
                ]),
              )),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(shape: BoxShape.circle, color: TributeColor.golden.withValues(alpha: 0.08)),
        child: Icon(Icons.group_rounded, size: 36, color: TributeColor.golden.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 20),
      const Text('No Circles Yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
      const SizedBox(height: 8),
      Text('Create a circle to pray with friends,\nor join one with an invite code.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.45))),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: TributeColor.golden, foregroundColor: TributeColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create a Circle', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _openJoin,
            child: const Text('Join with Code',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TributeColor.golden)),
          ),
        ]),
      ),
    ]);
  }
}
