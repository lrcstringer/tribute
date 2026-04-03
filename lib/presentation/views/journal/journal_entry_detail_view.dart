import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../theme/app_theme.dart';
import 'journal_entry_composer.dart';

class JournalEntryDetailView extends StatefulWidget {
  final JournalEntry entry;

  const JournalEntryDetailView({super.key, required this.entry});

  @override
  State<JournalEntryDetailView> createState() => _JournalEntryDetailViewState();
}

class _JournalEntryDetailViewState extends State<JournalEntryDetailView> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late JournalEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _togglePlayback() async {
    // Use the latest entry from the provider so a freshly uploaded URL is used.
    final current = context.read<JournalProvider>().getEntry(_entry.id) ?? _entry;
    final url = current.voiceUrl;
    if (url == null) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position == Duration.zero) {
        await _player.play(UrlSource(url));
      } else {
        await _player.resume();
      }
    }
  }

  Future<void> _openEdit() async {
    // Pass the freshest version of the entry to the composer.
    final provider = context.read<JournalProvider>();
    final toEdit = provider.getEntry(_entry.id) ?? _entry;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => JournalEntryComposer(initialEntry: toEdit)),
    );

    // Refresh from the raw entry list — not filteredEntries, which may exclude
    // this entry if a search query is active.
    if (mounted) {
      final updated = context.read<JournalProvider>().getEntry(_entry.id);
      if (updated != null) setState(() => _entry = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('Delete entry?',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16)),
        content: Text(
          'This entry will be permanently deleted.',
          style: TextStyle(color: MyWalkColor.warmWhite.withValues(alpha: 0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Use the freshest entry so any newly uploaded URLs are also deleted.
      final toDelete = context.read<JournalProvider>().getEntry(_entry.id) ?? _entry;
      await context.read<JournalProvider>().deleteEntry(toDelete);
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch for upload completion — uploadPending clears when MediaUploadService
    // commits to Firestore and JournalProvider.refreshEntry runs.
    // Watch for upload completion. context.select only rebuilds when the
    // selected value's reference changes (i.e. when refreshEntry replaces
    // the object in _entries), not on every notifyListeners call.
    final fresh = context.select<JournalProvider, JournalEntry?>(
      (p) => p.getEntry(widget.entry.id),
    );
    // Display uses the fresh snapshot; _entry is kept as a stable fallback
    // and updated by action methods (edit, delete) that explicitly refresh.
    final entry = fresh ?? _entry;

    final dateStr = _formatDate(entry.createdAt);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: Text(dateStr,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _openEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [
          // Upload pending banner
          if (entry.uploadPending)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: MyWalkColor.softGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MyWalkColor.softGold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: MyWalkColor.softGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Media uploading...',
                    style: TextStyle(
                      fontSize: 13,
                      color: MyWalkColor.softGold.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

          // Source chip
          _SourceChipRow(entry: entry),

          // Body text
          if (entry.text != null && entry.text!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.text!,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                height: 1.7,
              ),
            ),
          ],

          // Images
          if (entry.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...entry.imageUrls.map((url) => _NetworkImageTile(url: url)),
          ],

          // Voice playback
          if (entry.voiceUrl != null && !entry.uploadPending) ...[
            const SizedBox(height: 20),
            _VoicePlaybackBar(
              isPlaying: _isPlaying,
              position: _position,
              duration: _duration,
              onToggle: _togglePlayback,
              onSeek: (pos) => _player.seek(pos),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }
}

// ── Source Chip Row ─────────────────────────────────────────────────────────

class _SourceChipRow extends StatelessWidget {
  final JournalEntry entry;

  const _SourceChipRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;
    IconData icon;

    if (entry.habitName != null) {
      chipColor = MyWalkColor.golden;
      label = entry.habitName!;
      icon = Icons.repeat;
    } else if (entry.fruitTag != null) {
      chipColor = entry.fruitTag!.color;
      label = entry.fruitTag!.label;
      icon = entry.fruitTag!.icon;
    } else {
      chipColor = MyWalkColor.softGold;
      label = 'Journal';
      icon = Icons.book_outlined;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: chipColor.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: chipColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Network Image Tile ───────────────────────────────────────────────────────

class _NetworkImageTile extends StatelessWidget {
  final String url;

  const _NetworkImageTile({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreen(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => Container(
            height: 160,
            color: MyWalkColor.cardBackground,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Voice Playback Bar ───────────────────────────────────────────────────────

class _VoicePlaybackBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;

  const _VoicePlaybackBar({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final current = position.inMilliseconds.toDouble().clamp(0.0, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MyWalkColor.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MyWalkColor.softGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20,
                color: MyWalkColor.softGold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: MyWalkColor.softGold.withValues(alpha: 0.7),
                inactiveTrackColor: Colors.white12,
                thumbColor: MyWalkColor.softGold,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 2,
              ),
              child: Slider(
                value: current,
                min: 0,
                max: total,
                onChanged: (v) => onSeek(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_fmt(position)} / ${_fmt(duration)}',
            style: TextStyle(
              fontSize: 11,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
