import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/journal_entry.dart';
import '../../../domain/entities/journal_theme.dart';
import '../../../domain/entities/fruit.dart';
import '../../providers/journal_provider.dart';
import '../../providers/journal_theme_provider.dart';
import '../../theme/app_theme.dart';
import 'journal_entry_composer.dart';
import 'journal_entry_detail_view.dart';
import 'journal_theme_picker.dart';

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

  void _showSortSheet(
      BuildContext context, JournalProvider provider, JournalTheme theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final current = provider.sortOrder;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              for (final order in JournalSortOrder.values)
                ListTile(
                  title: Text(_sortLabel(order),
                      style: TextStyle(
                          color: theme.textPrimary, fontSize: 14)),
                  trailing: current == order
                      ? Icon(Icons.check,
                          color: theme.textSecondary, size: 18)
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
    final theme = context.watch<JournalThemeProvider>().theme;
    final entries = provider.filteredEntries;

    return Scaffold(
      backgroundColor: theme.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const JournalEntryComposer()),
        ),
        backgroundColor: theme.textPrimary,
        foregroundColor: theme.bgCard,
        child: const Icon(Icons.edit_outlined),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ───────────────────────────────────────────
          SliverAppBar(
            backgroundColor: theme.bgPrimary,
            foregroundColor: theme.textPrimary,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    theme.heroImageAsset,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.bgPrimary.withValues(alpha: 0.5),
                          theme.bgPrimary,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 14,
                    child: Text(
                      'Journal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.palette_outlined,
                    size: 22, color: theme.textPrimary),
                onPressed: () => showJournalThemePicker(context),
                tooltip: 'Theme',
              ),
              IconButton(
                icon: Icon(Icons.sort, size: 22, color: theme.textPrimary),
                onPressed: () => _showSortSheet(context, provider, theme),
                tooltip: 'Sort',
              ),
            ],
          ),

          // ── Search bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: provider.setSearchQuery,
                style: TextStyle(color: theme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search entries...',
                  hintStyle: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: theme.textSecondary),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: theme.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.bgCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // ── Loading ──────────────────────────────────────────────────────
          if (provider.isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.textSecondary,
                  strokeWidth: 2,
                ),
              ),
            )

          // ── Empty state ──────────────────────────────────────────────────
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
                        color: theme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.searchQuery.isNotEmpty
                            ? 'No entries match your search'
                            : 'Your spiritual journey starts here.\nTap + to add your first entry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // ── Entry list ────────────────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = entries[i];
                    return _JournalEntryCard(
                      entry: entry,
                      theme: theme,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JournalEntryDetailView(entry: entry),
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
  final JournalTheme theme;
  final VoidCallback onTap;

  const _JournalEntryCard({
    required this.entry,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.15)),
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
                    color: theme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (entry.uploadPending)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.cloud_upload_outlined,
                        size: 14,
                        color: theme.textSecondary.withValues(alpha: 0.6)),
                  ),
                if (entry.imageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.image_outlined,
                        size: 14,
                        color: theme.textSecondary.withValues(alpha: 0.5)),
                  ),
                if (entry.voiceUrl != null)
                  Icon(Icons.mic_outlined,
                      size: 14,
                      color: theme.textSecondary.withValues(alpha: 0.5)),
              ],
            ),

            const SizedBox(height: 8),

            // Source chip
            _SourceChip(entry: entry, theme: theme),

            // Text preview
            if (entry.text != null && entry.text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textPrimary,
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
  final JournalTheme theme;

  const _SourceChip({required this.entry, required this.theme});

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
      chipColor = theme.textSecondary;
      label = 'Journal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: chipColor.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
