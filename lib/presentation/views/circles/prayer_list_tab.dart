import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/prayer_list_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';

class PrayerListTab extends StatelessWidget {
  final String circleId;
  const PrayerListTab({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerListProvider>(
      builder: (context, provider, _) {
        final uid = AuthService.shared.userId ?? '';
        final active = provider.activeFor(circleId);
        final answered = provider.answeredFor(circleId);
        final isLoading = provider.isLoading(circleId);

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _showAddSheet(context),
            backgroundColor: MyWalkColor.golden,
            foregroundColor: MyWalkColor.charcoal,
            child: const Icon(Icons.add),
          ),
          body: isLoading && active.isEmpty
              ? const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              : RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => provider.load(circleId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (active.isEmpty && answered.isEmpty)
                        _emptyState()
                      else ...[
                        if (active.isNotEmpty) ...[
                          _sectionHeader('Active (${active.length})'),
                          const SizedBox(height: 8),
                          ...active.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PrayerRequestCard(
                              request: r, uid: uid, circleId: circleId),
                          )),
                        ],
                        if (answered.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionHeader('Answered (${answered.length})'),
                          const SizedBox(height: 8),
                          ...answered.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PrayerRequestCard(
                              request: r, uid: uid, circleId: circleId),
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

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.volunteer_activism_rounded, size: 40,
            color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text('No prayer requests yet.',
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text('Tap + to share one with your circle.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2));
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => AddPrayerRequestSheet(circleId: circleId),
    );
  }
}

// ─── Prayer Request Card ──────────────────────────────────────────────────────

class _PrayerRequestCard extends StatelessWidget {
  final PrayerRequest request;
  final String uid;
  final String circleId;

  const _PrayerRequestCard({
    required this.request,
    required this.uid,
    required this.circleId,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthor = request.isAuthor(uid);
    final hasPrayed = request.hasPrayed(uid);
    final isAnswered = request.status == PrayerRequestStatus.answered;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAnswered
            ? MyWalkColor.sage.withValues(alpha: 0.06)
            : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswered
              ? MyWalkColor.sage.withValues(alpha: 0.2)
              : MyWalkColor.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(request.authorDisplayName,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isAuthor ? MyWalkColor.golden : MyWalkColor.softGold)),
          ),
          if (isAnswered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MyWalkColor.sage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Answered',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MyWalkColor.sage)),
            ),
          const SizedBox(width: 4),
          Text(_relativeTime(request.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(height: 8),
        Text(request.requestText,
            style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite.withValues(alpha: 0.9), height: 1.45)),
        if (isAnswered && request.answeredNote != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MyWalkColor.sage.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(request.answeredNote!,
                style: TextStyle(fontSize: 13, color: MyWalkColor.sage.withValues(alpha: 0.85), height: 1.4)),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (!isAnswered)
            _prayButton(context, hasPrayed),
          const Spacer(),
          if (isAuthor && !isAnswered)
            _markAnsweredButton(context),
        ]),
      ]),
    );
  }

  Widget _prayButton(BuildContext context, bool hasPrayed) {
    final provider = context.read<PrayerListProvider>();
    return GestureDetector(
      onTap: hasPrayed ? null : () => provider.prayFor(circleId, request.id, uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasPrayed
              ? MyWalkColor.golden.withValues(alpha: 0.12)
              : MyWalkColor.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasPrayed
                ? MyWalkColor.golden.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.volunteer_activism_rounded, size: 13,
              color: hasPrayed ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 5),
          Text(
            hasPrayed ? 'Prayed (${request.prayerCount})' : 'Pray (${request.prayerCount})',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: hasPrayed ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _markAnsweredButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMarkAnsweredDialog(context),
      child: Text('Mark Answered',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.sage.withValues(alpha: 0.8))),
    );
  }

  void _showMarkAnsweredDialog(BuildContext context) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Mark as Answered', style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: TextField(
          controller: noteController,
          maxLength: 200,
          style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Share how God answered this (optional)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
            filled: true,
            fillColor: MyWalkColor.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
              Navigator.pop(dialogContext);
              context.read<PrayerListProvider>().markAnswered(circleId, request.id, answeredNote: note);
            },
            child: const Text('Confirm', style: TextStyle(color: MyWalkColor.golden)),
          ),
        ],
      ),
    );
  }

  String _relativeTime(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ─── Add Prayer Request Sheet ─────────────────────────────────────────────────

class AddPrayerRequestSheet extends StatefulWidget {
  final String circleId;
  const AddPrayerRequestSheet({super.key, required this.circleId});

  @override
  State<AddPrayerRequestSheet> createState() => _AddPrayerRequestSheetState();
}

class _AddPrayerRequestSheetState extends State<AddPrayerRequestSheet> {
  final _textController = TextEditingController();
  PrayerDuration _duration = PrayerDuration.ongoing;
  bool _anonymous = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Share a Prayer Request',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLength: 500,
            maxLines: 4,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'What would you like your circle to pray for?',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true,
              fillColor: MyWalkColor.inputBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: MyWalkColor.softGold)),
          const SizedBox(height: 8),
          Row(children: PrayerDuration.values.map((d) {
            final selected = _duration == d;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _duration = d),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.golden.withValues(alpha: 0.12) : MyWalkColor.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? MyWalkColor.golden.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Center(child: Text(_durationLabel(d),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                          color: selected ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.5)))),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _anonymous = !_anonymous),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _anonymous ? MyWalkColor.golden.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _anonymous ? MyWalkColor.golden : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: _anonymous
                    ? const Icon(Icons.check, size: 14, color: MyWalkColor.golden)
                    : null,
              ),
              const SizedBox(width: 10),
              Text('Post anonymously',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
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
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.charcoal))
                  : const Text('Share with Circle',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  String _durationLabel(PrayerDuration d) {
    switch (d) {
      case PrayerDuration.thisWeek: return 'This Week';
      case PrayerDuration.ongoing: return 'Ongoing';
      case PrayerDuration.untilRemoved: return 'Until Removed';
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please write your prayer request.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<PrayerListProvider>().createRequest(
        circleId: widget.circleId, text: text, duration: _duration, anonymous: _anonymous);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}
