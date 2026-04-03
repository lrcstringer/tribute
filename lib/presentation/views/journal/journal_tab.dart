import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/journal_entry.dart';
import '../../../domain/entities/fruit.dart';
import '../../providers/journal_provider.dart';
import '../../theme/app_theme.dart';
import 'journal_entry_composer.dart';
import 'journal_entry_detail_view.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context, JournalProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MyWalkColor.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final current = provider.sortOrder;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              for (final order in JournalSortOrder.values)
                ListTile(
                  title: Text(_sortLabel(order),
                      style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14)),
                  trailing: current == order
                      ? const Icon(Icons.check, color: MyWalkColor.softGold, size: 18)
                      : null,
                  onTap: () {
                    provider.setSortOrder(order);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(JournalSortOrder order) {
    switch (order) {
      case JournalSortOrder.newestFirst:
        return 'Newest first';
      case JournalSortOrder.oldestFirst:
        return 'Oldest first';
      case JournalSortOrder.byHabit:
        return 'By habit';
      case JournalSortOrder.byFruit:
        return 'By fruit';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalProvider>();
    final entries = provider.filteredEntries;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const JournalEntryComposer()),
        ),
        backgroundColor: MyWalkColor.golden,
        foregroundColor: MyWalkColor.charcoal,
        child: const Icon(Icons.edit_outlined),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            pinned: true,
            title: const Text(
              'Journal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, size: 22),
                onPressed: () => _showSortSheet(context, provider),
                tooltip: 'Sort',
              ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: provider.setSearchQuery,
                style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search entries...',
                  hintStyle: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: MyWalkColor.warmWhite.withValues(alpha: 0.35)),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
                          onPressed: () {
                            _searchCtrl.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: MyWalkColor.inputBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Loading
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: MyWalkColor.softGold,
                  strokeWidth: 2,
                ),
              ),
            )

          // Empty state
          else if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.searchQuery.isNotEmpty
                            ? 'No entries match your search'
                            : 'Your spiritual journey starts here.\nTap + to add your first entry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // Entry list
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = entries[i];
                    return _JournalEntryCard(
                      entry: entry,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JournalEntryDetailView(entry: entry),
                        ),
                      ),
                    );
                  },
                  childCount: entries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Entry Card ───────────────────────────────────────────────────────────────

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const _JournalEntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: date + media indicators
            Row(
              children: [
                Text(
                  _shortDate(entry.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                if (entry.uploadPending)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.cloud_upload_outlined,
                        size: 14,
                        color: MyWalkColor.softGold.withValues(alpha: 0.5)),
                  ),
                if (entry.imageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.image_outlined,
                        size: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.35)),
                  ),
                if (entry.voiceUrl != null)
                  Icon(Icons.mic_outlined,
                      size: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.35)),
              ],
            ),

            const SizedBox(height: 8),

            // Source chip
            _SourceChip(entry: entry),

            // Text preview
            if (entry.text != null && entry.text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Source Chip (card) ───────────────────────────────────────────────────────

class _SourceChip extends StatelessWidget {
  final JournalEntry entry;

  const _SourceChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;

    if (entry.habitName != null) {
      chipColor = MyWalkColor.golden;
      label = entry.habitName!;
    } else if (entry.fruitTag != null) {
      chipColor = entry.fruitTag!.color;
      label = entry.fruitTag!.label;
    } else {
      chipColor = MyWalkColor.softGold;
      label = 'Journal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: chipColor.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
