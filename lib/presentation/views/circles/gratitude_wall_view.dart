import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Embeddable gratitude wall widget (used inside CircleDetailView).
class GratitudeWallWidget extends StatefulWidget {
  final String circleId;
  const GratitudeWallWidget({super.key, required this.circleId});

  @override
  State<GratitudeWallWidget> createState() => _GratitudeWallWidgetState();
}

class _GratitudeWallWidgetState extends State<GratitudeWallWidget> {
  List<SharedGratitudeItem> _gratitudes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasOlderWeeks = true;
  int _weeksBack = 0;
  int _newCount = 0;
  bool _showNewBadge = false;
  SharedGratitudeItem? _deleteTarget;

  @override
  void initState() {
    super.initState();
    _loadWall();
    _loadNewCount();
    _markSeen();
  }

  Future<void> _loadWall() async {
    setState(() => _isLoading = true);
    try {
      final r = await APIService.shared.getGratitudeWall(widget.circleId, weeksBack: _weeksBack);
      if (mounted) setState(() { _gratitudes = r.gratitudes; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNewCount() async {
    try {
      final r = await APIService.shared.getGratitudeNewCount(widget.circleId);
      if (mounted && r.newCount > 0) {
        setState(() { _newCount = r.newCount; _showNewBadge = true; });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showNewBadge = false);
        });
      }
    } catch (_) {}
  }

  Future<void> _markSeen() async {
    try { await APIService.shared.markGratitudesSeen(widget.circleId); } catch (_) {}
  }

  void _loadPreviousWeek() {
    setState(() => _isLoadingMore = true);
    final nextWeek = _weeksBack + 1;
    APIService.shared.getGratitudeWall(widget.circleId, weeksBack: nextWeek).then((r) {
      if (!mounted) return;
      if (r.gratitudes.isEmpty) {
        setState(() { _hasOlderWeeks = false; _isLoadingMore = false; });
      } else {
        setState(() {
          _gratitudes.addAll(r.gratitudes);
          _weeksBack = nextWeek;
          _isLoadingMore = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _deleteGratitude(SharedGratitudeItem item) async {
    try {
      await APIService.shared.deleteGratitude(widget.circleId, item.id);
      if (mounted) setState(() => _gratitudes.removeWhere((g) => g.id == item.id));
    } catch (_) {}
  }

  String _relativeTime(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(date.weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GRATITUDE WALL',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
      const SizedBox(height: 10),
      if (_isLoading)
        const Center(child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: TributeColor.golden, strokeWidth: 2),
        ))
      else if (_gratitudes.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              _weeksBack == 0 ? 'No gratitudes shared this week yet' : 'No gratitudes this week',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
        )
      else ...[
        if (_showNewBadge && _newCount > 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('$_newCount new gratitude${_newCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TributeColor.golden)),
            ),
          ),
        ..._gratitudes.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _gratitudeCard(item),
            )),
        if (_hasOlderWeeks)
          Center(
            child: TextButton(
              onPressed: _isLoadingMore ? null : _loadPreviousWeek,
              child: _isLoadingMore
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: TributeColor.golden))
                  : Text('Previous weeks',
                      style: TextStyle(fontSize: 12, color: TributeColor.golden.withValues(alpha: 0.7))),
            ),
          ),
      ],
      if (_deleteTarget != null)
        _confirmDeleteDialog(),
    ]);
  }

  Widget _gratitudeCard(SharedGratitudeItem item) {
    return GestureDetector(
      onLongPress: item.isMine
          ? () => setState(() => _deleteTarget = item)
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF353548), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              item.isAnonymous
                  ? 'Someone in your circle'
                  : (item.displayName?.split(' ').first ?? 'Member'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: item.isAnonymous
                      ? const Color(0xFF9A98A0)
                      : TributeColor.warmWhite),
            ),
            const Spacer(),
            Text(_relativeTime(item.sharedAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B7B))),
          ]),
          const SizedBox(height: 6),
          Text(item.gratitudeText,
              style: const TextStyle(fontSize: 14, color: TributeColor.warmWhite, height: 1.5)),
        ]),
      ),
    );
  }

  Widget _confirmDeleteDialog() {
    return AlertDialog(
      backgroundColor: TributeColor.cardBackground,
      title: const Text('Delete Gratitude', style: TextStyle(color: TributeColor.warmWhite)),
      content: Text(
        'This gratitude will be removed from the wall for all circle members.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _deleteTarget = null),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        TextButton(
          onPressed: () {
            final t = _deleteTarget;
            setState(() => _deleteTarget = null);
            if (t != null) _deleteGratitude(t);
          },
          child: const Text('Delete', style: TextStyle(color: TributeColor.warmCoral)),
        ),
      ],
    );
  }
}

/// Full-screen gratitude wall view (standalone navigation target).
class GratitudeWallView extends StatelessWidget {
  final String circleId;
  const GratitudeWallView({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      appBar: AppBar(
        backgroundColor: TributeColor.charcoal,
        title: const Text('Gratitude Wall',
            style: TextStyle(color: TributeColor.warmWhite, fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GratitudeWallWidget(circleId: circleId),
        ),
      ),
    );
  }
}
