import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/encouragement_provider.dart';
import '../../providers/milestone_share_provider.dart';
import '../../providers/circle_habit_milestone_provider.dart';
import '../../providers/weekly_pulse_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';

class ActivityTab extends StatelessWidget {
  final String circleId;
  final List<CircleMember> members;
  const ActivityTab({super.key, required this.circleId, required this.members});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.shared.userId ?? '';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: MyWalkColor.charcoal,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: TabBar(
            labelColor: MyWalkColor.golden,
            unselectedLabelColor: MyWalkColor.softGold,
            indicatorColor: MyWalkColor.golden,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Encouragements'), Tab(text: 'Milestones'), Tab(text: 'Pulse')],
          ),
        ),
        body: TabBarView(
          children: [
            _EncouragementsList(circleId: circleId, uid: uid, members: members),
            _MilestonesList(circleId: circleId, uid: uid),
            _PulseView(circleId: circleId, uid: uid),
          ],
        ),
      ),
    );
  }
}

// ─── Encouragements ───────────────────────────────────────────────────────────

class _EncouragementsList extends StatelessWidget {
  final String circleId;
  final String uid;
  final List<CircleMember> members;
  const _EncouragementsList(
      {required this.circleId, required this.uid, required this.members});

  @override
  Widget build(BuildContext context) {
    return Consumer<EncouragementProvider>(
      builder: (context, provider, _) {
        final received = provider.receivedFor(circleId);
        final sent = provider.sentFor(circleId);
        final isLoading = provider.isLoading(circleId);

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _showSendSheet(context),
            backgroundColor: MyWalkColor.softGold,
            foregroundColor: MyWalkColor.charcoal,
            child: const Icon(Icons.favorite_rounded),
          ),
          body: isLoading && received.isEmpty
              ? const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              : RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => provider.load(circleId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (received.isEmpty && sent.isEmpty)
                        _emptyState()
                      else ...[
                        if (received.isNotEmpty) ...[
                          _sectionHeader('Received (${received.length})'),
                          const SizedBox(height: 8),
                          ...received.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _EncouragementCard(
                              enc: e, uid: uid, circleId: circleId, isReceived: true, members: members),
                          )),
                        ],
                        if (sent.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionHeader('Sent (${sent.length})'),
                          const SizedBox(height: 8),
                          ...sent.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _EncouragementCard(
                              enc: e, uid: uid, circleId: circleId, isReceived: false, members: members),
                          )),
                        ],
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      Icon(Icons.favorite_border_rounded, size: 40, color: Colors.white.withValues(alpha: 0.15)),
      const SizedBox(height: 12),
      Text('No encouragements yet.',
          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
      const SizedBox(height: 6),
      Text('Tap ♥ to send one to someone in your circle.',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
    ]),
  );

  Widget _sectionHeader(String title) => Text(title.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2));

  void _showSendSheet(BuildContext context) {
    final otherMembers = members.where((m) => m.userId != uid).toList();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => SendEncouragementSheet(circleId: circleId, members: otherMembers),
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  final Encouragement enc;
  final String uid;
  final String circleId;
  final bool isReceived;
  final List<CircleMember> members;
  const _EncouragementCard(
      {required this.enc, required this.uid,
      required this.circleId, required this.isReceived,
      required this.members});

  @override
  Widget build(BuildContext context) {
    final senderLabel = enc.isAnonymous ? 'Anonymous' : (enc.senderDisplayName ?? 'Circle Member');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isReceived && !enc.isRead) {
        context.read<EncouragementProvider>().markRead(circleId, enc.id);
      }
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReceived && !enc.isRead
            ? MyWalkColor.softGold.withValues(alpha: 0.05)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReceived && !enc.isRead
              ? MyWalkColor.softGold.withValues(alpha: 0.15)
              : MyWalkColor.cardBorder,
          width: 0.5,
        ),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MyWalkColor.softGold.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.favorite_rounded, size: 16, color: MyWalkColor.softGold),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isReceived ? 'From $senderLabel' : 'To ${members.firstWhere((m) => m.userId == enc.recipientId, orElse: () => CircleMember(userId: '', role: 'member', joinedAt: '')).displayName}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 3),
          Text(enc.displayMessage,
              style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
        ])),
        if (isReceived && !enc.isRead)
          Container(width: 7, height: 7,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.softGold)),
      ]),
    );
  }
}

// ─── Send Encouragement Sheet ─────────────────────────────────────────────────

class SendEncouragementSheet extends StatefulWidget {
  final String circleId;
  final List<CircleMember> members;
  const SendEncouragementSheet({super.key, required this.circleId, required this.members});

  @override
  State<SendEncouragementSheet> createState() => _SendEncouragementSheetState();
}

class _SendEncouragementSheetState extends State<SendEncouragementSheet> {
  final Set<String> _selectedMemberIds = {};
  String? _selectedPresetKey;
  final _customController = TextEditingController();
  bool _isAnonymous = false;
  bool _useCustom = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() { _customController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Send Encouragement',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Send', style: TextStyle(color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16,
            MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Send To'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.members.map((m) {
              final selected = _selectedMemberIds.contains(m.userId);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedMemberIds.remove(m.userId);
                  } else {
                    _selectedMemberIds.add(m.userId);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.softGold.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? MyWalkColor.softGold.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Text(m.displayName,
                      style: TextStyle(fontSize: 13, color: selected ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.5))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _label('Message'),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _useCustom = !_useCustom),
              child: Text(_useCustom ? 'Use Preset' : 'Write Custom',
                  style: const TextStyle(fontSize: 12, color: MyWalkColor.golden)),
            ),
          ]),
          const SizedBox(height: 8),
          if (!_useCustom) ...[
            ...Encouragement.presetEntries.map((e) {
              final selected = _selectedPresetKey == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedPresetKey = e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.softGold.withValues(alpha: 0.08) : MyWalkColor.inputBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? MyWalkColor.softGold.withValues(alpha: 0.3) : Colors.transparent),
                  ),
                  child: Text(e.value,
                      style: TextStyle(fontSize: 13,
                          color: selected ? MyWalkColor.warmWhite : Colors.white.withValues(alpha: 0.6))),
                ),
              );
            }),
          ] else ...[
            TextField(
              controller: _customController,
              maxLength: 200, maxLines: 3,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a personal message…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                filled: true, fillColor: MyWalkColor.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            child: Row(children: [
              Icon(_isAnonymous ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18, color: _isAnonymous ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text('Send anonymously',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
        ]),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)));

  Future<void> _send() async {
    if (_selectedMemberIds.isEmpty) { setState(() => _error = 'Select at least one recipient.'); return; }
    final isCustom = _useCustom;
    final text = _customController.text.trim();
    if (isCustom && text.isEmpty) { setState(() => _error = 'Write a message.'); return; }
    if (!isCustom && _selectedPresetKey == null) { setState(() => _error = 'Select a message.'); return; }

    setState(() { _sending = true; _error = null; });
    try {
      final provider = context.read<EncouragementProvider>();
      for (final recipientId in _selectedMemberIds) {
        await provider.send(
          circleId: widget.circleId,
          recipientId: recipientId,
          messageType: isCustom ? EncouragementMessageType.custom : EncouragementMessageType.preset,
          presetKey: isCustom ? null : _selectedPresetKey,
          customText: isCustom ? text : null,
          isAnonymous: _isAnonymous,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _sending = false; });
    }
  }
}

// ─── Milestones ───────────────────────────────────────────────────────────────

class _MilestonesList extends StatelessWidget {
  final String circleId;
  final String uid;
  const _MilestonesList({required this.circleId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CircleHabitMilestoneProvider, MilestoneShareProvider>(
      builder: (context, circleProvider, shareProvider, _) {
        final circleMilestones = circleProvider.milestonesFor(circleId);
        final shares = shareProvider.sharesFor(circleId);
        final isLoading = (circleProvider.isLoading(circleId) && circleMilestones.isEmpty) ||
            (shareProvider.isLoading(circleId) && shares.isEmpty);

        if (isLoading) {
          return const Center(child: CircularProgressIndicator(color: MyWalkColor.golden));
        }

        if (circleMilestones.isEmpty && shares.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_border_rounded, size: 40, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Text('No milestones yet.',
                  style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
            ]),
          ));
        }

        final items = <Widget>[
          if (circleMilestones.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Text('Circle Milestones',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.8)),
            ),
            ...circleMilestones.map((m) => _CircleHabitMilestoneCard(milestone: m)),
          ],
          if (shares.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(0, circleMilestones.isNotEmpty ? 20 : 4, 0, 8),
              child: Text('Member Milestones',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.8)),
            ),
            ...shares.map((s) => _MilestoneCard(share: s, uid: uid, circleId: circleId)),
          ],
        ];

        return RefreshIndicator(
          color: MyWalkColor.golden,
          backgroundColor: MyWalkColor.cardBackground,
          onRefresh: () => Future.wait([
            circleProvider.load(circleId),
            shareProvider.load(circleId),
          ]),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: items.length,
            separatorBuilder: (_, i) {
              final item = items[i];
              if (item is Padding) return const SizedBox.shrink();
              return const SizedBox(height: 10);
            },
            itemBuilder: (_, i) => items[i],
          ),
        );
      },
    );
  }
}

class _CircleHabitMilestoneCard extends StatelessWidget {
  final CircleHabitMilestone milestone;
  const _CircleHabitMilestoneCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: MyWalkColor.golden.withValues(alpha: 0.12)),
          child: const Icon(Icons.groups_rounded, size: 20, color: MyWalkColor.golden),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Circle milestone!',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 2),
          Text(milestone.displayLabel,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
        ])),
      ]),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MilestoneShare share;
  final String uid;
  final String circleId;
  const _MilestoneCard({required this.share, required this.uid, required this.circleId});

  @override
  Widget build(BuildContext context) {
    final hasCelebrated = share.hasCelebrated(uid);
    final isAuthor = share.isAuthor(uid);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: MyWalkColor.golden.withValues(alpha: 0.1)),
          child: const Icon(Icons.star_rounded, size: 20, color: MyWalkColor.golden)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAuthor ? 'You hit a milestone!' : '${share.userDisplayName} hit a milestone!',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 2),
          Text(share.displayLabel,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
          if (share.celebrationCount > 0) ...[
            const SizedBox(height: 4),
            Text('🎉 ${share.celebrationCount} celebrated',
                style: TextStyle(fontSize: 11, color: MyWalkColor.golden.withValues(alpha: 0.7))),
          ],
        ])),
        if (!isAuthor)
          GestureDetector(
            onTap: hasCelebrated ? null :
                () => context.read<MilestoneShareProvider>().celebrate(circleId, share.id, uid),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: hasCelebrated
                    ? MyWalkColor.golden.withValues(alpha: 0.1)
                    : MyWalkColor.inputBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(hasCelebrated ? '🎉' : 'Celebrate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: hasCelebrated ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5))),
            ),
          ),
      ]),
    );
  }
}

// ─── Pulse ────────────────────────────────────────────────────────────────────

class _PulseView extends StatelessWidget {
  final String circleId;
  final String uid;
  const _PulseView({required this.circleId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyPulseProvider>(
      builder: (context, provider, _) {
        final pulse = provider.pulseFor(circleId);
        final myResponse = provider.myResponseFor(circleId);
        final hasResponded = provider.hasResponded(circleId);
        final isLoading = provider.isLoading(circleId);

        if (isLoading && pulse == null) {
          return const Center(child: CircularProgressIndicator(color: MyWalkColor.golden));
        }

        return RefreshIndicator(
          color: MyWalkColor.golden,
          backgroundColor: MyWalkColor.cardBackground,
          onRefresh: () => provider.load(circleId, uid),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              if (!hasResponded)
                _CheckInBanner(circleId: circleId, uid: uid),
              if (hasResponded && myResponse != null) ...[
                _MyResponseCard(response: myResponse),
                const SizedBox(height: 16),
              ],
              if (pulse != null) ...[
                _PulseSummaryCard(pulse: pulse),
                const SizedBox(height: 16),
                if (pulse.responses.isNotEmpty)
                  ..._buildResponses(pulse.responses),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('No pulse data this week.',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildResponses(List<PulseResponse> responses) {
    return [
      Text('THIS WEEK',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
      const SizedBox(height: 8),
      ...responses.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ResponseCard(response: r),
      )),
    ];
  }
}

class _CheckInBanner extends StatelessWidget {
  final String circleId;
  final String uid;
  const _CheckInBanner({required this.circleId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _softBlue.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How are you doing this week?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 4),
        Text('Your circle wants to know. This helps them pray for you.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5), height: 1.4)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _showCheckIn(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _softBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _softBlue.withValues(alpha: 0.3)),
            ),
            child: const Center(child: Text('Check In',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _softBlue))),
          ),
        ),
      ]),
    );
  }

  void _showCheckIn(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => PulseCheckInSheet(circleId: circleId, uid: uid),
    );
  }
}

class _MyResponseCard extends StatelessWidget {
  final PulseResponse response;
  const _MyResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(response.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(children: [
        Icon(_statusIcon(response.status), size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your check-in this week',
              style: TextStyle(fontSize: 12, color: MyWalkColor.softGold)),
          Text(_statusLabel(response.status),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ])),
        if (response.isAnonymous)
          Text('Anonymous', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
      ]),
    );
  }
}

class _PulseSummaryCard extends StatelessWidget {
  final WeeklyPulse pulse;
  const _PulseSummaryCard({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${pulse.responseCount} check-ins this week',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        if (pulse.needsPrayerCount > 0) ...[
          const SizedBox(height: 6),
          Text('${pulse.needsPrayerCount} ${pulse.needsPrayerCount == 1 ? 'person needs' : 'people need'} prayer',
              style: const TextStyle(fontSize: 13, color: MyWalkColor.warmCoral)),
        ],
        const SizedBox(height: 12),
        ...PulseStatus.values.map((s) {
          final count = pulse.countFor(s);
          final frac = pulse.responseCount > 0 ? count / pulse.responseCount : 0.0;
          final color = _statusColor(s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 80,
                  child: Text(_statusLabel(s),
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)))),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac, minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 20,
                  child: Text('$count',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)))),
            ]),
          );
        }),
      ]),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final PulseResponse response;
  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final name = response.isAnonymous ? 'Anonymous' : (response.userDisplayName ?? 'Circle Member');
    final color = _statusColor(response.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: MyWalkDecorations.card,
      child: Row(children: [
        Icon(_statusIcon(response.status), size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(name,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)))),
        Text(_statusLabel(response.status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

// ─── Pulse Check-In Sheet ─────────────────────────────────────────────────────

class PulseCheckInSheet extends StatefulWidget {
  final String circleId;
  final String uid;
  const PulseCheckInSheet({super.key, required this.circleId, required this.uid});

  @override
  State<PulseCheckInSheet> createState() => _PulseCheckInSheetState();
}

class _PulseCheckInSheetState extends State<PulseCheckInSheet> {
  PulseStatus? _selected;
  bool _isAnonymous = false;
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('How are you doing this week?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 4),
          Text('Your circle will see your check-in.',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          ...PulseStatus.values.map((s) {
            final selected = _selected == s;
            final color = _statusColor(s);
            return GestureDetector(
              onTap: () => setState(() => _selected = s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.1) : MyWalkColor.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? color.withValues(alpha: 0.4) : Colors.transparent),
                ),
                child: Row(children: [
                  Icon(_statusIcon(s), size: 18, color: selected ? color : Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(width: 12),
                  Text(_statusLabel(s),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                          color: selected ? color : Colors.white.withValues(alpha: 0.7))),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            child: Row(children: [
              Icon(_isAnonymous ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18, color: _isAnonymous ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text('Share anonymously',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden, foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Check In',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) { setState(() => _error = 'Select how you\'re doing.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<WeeklyPulseProvider>().submit(
        circleId: widget.circleId, status: _selected!,
        isAnonymous: _isAnonymous, uid: widget.uid);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(PulseStatus s) {
  switch (s) {
    case PulseStatus.encouraged: return MyWalkColor.golden;
    case PulseStatus.steady: return MyWalkColor.sage;
    case PulseStatus.struggling: return MyWalkColor.softGold;
    case PulseStatus.needsPrayer: return MyWalkColor.warmCoral;
  }
}

IconData _statusIcon(PulseStatus s) {
  switch (s) {
    case PulseStatus.encouraged: return Icons.sentiment_very_satisfied_rounded;
    case PulseStatus.steady: return Icons.sentiment_satisfied_rounded;
    case PulseStatus.struggling: return Icons.sentiment_dissatisfied_rounded;
    case PulseStatus.needsPrayer: return Icons.volunteer_activism_rounded;
  }
}

String _statusLabel(PulseStatus s) {
  switch (s) {
    case PulseStatus.encouraged: return 'Encouraged';
    case PulseStatus.steady: return 'Steady';
    case PulseStatus.struggling: return 'Struggling';
    case PulseStatus.needsPrayer: return 'Need Prayer';
  }
}

// softBlue is not in the brand palette — use a local constant.
const _softBlue = Color(0xFF6B9BB8);
