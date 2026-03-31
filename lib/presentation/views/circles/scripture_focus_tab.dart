import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../providers/scripture_focus_provider.dart';
import '../../../domain/entities/circle.dart';
import '../../theme/app_theme.dart';

class ScriptureFocusTab extends StatelessWidget {
  final String circleId;
  final CircleSettings settings;
  const ScriptureFocusTab({super.key, required this.circleId, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScriptureFocusProvider>(
      builder: (context, provider, _) {
        final uid = AuthService.shared.userId ?? '';
        final focus = provider.focusFor(circleId);
        final reflections = provider.reflectionsFor(circleId);
        final isLoading = provider.isLoading(circleId);
        final hasSubmitted = provider.hasSubmittedReflection(circleId);

        final canSet = settings.scriptureFocusPermission == 'any_member' ||
            uid.isNotEmpty; // admin check handled server-side; UI shows button to all and server rejects non-admins

        return Scaffold(
          backgroundColor: MyWalkColor.charcoal,
          floatingActionButton: canSet
              ? FloatingActionButton.small(
                  onPressed: () => _showSetFocusSheet(context),
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  tooltip: 'Set Scripture Focus',
                  child: const Icon(Icons.edit_rounded),
                )
              : null,
          body: isLoading && focus == null
              ? const Center(child: CircularProgressIndicator(color: MyWalkColor.golden))
              : RefreshIndicator(
                  color: MyWalkColor.golden,
                  backgroundColor: MyWalkColor.cardBackground,
                  onRefresh: () => provider.load(circleId, uid),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (focus == null)
                        _emptyState(context)
                      else ...[
                        _FocusCard(focus: focus),
                        const SizedBox(height: 16),
                        _reflectionSection(context, focus, reflections, hasSubmitted, uid),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.menu_book_rounded, size: 40, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text('No Scripture focus this week.',
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        Text('Tap ✏ to set one for your circle.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
      ]),
    );
  }

  Widget _reflectionSection(
    BuildContext context,
    ScriptureFocus focus,
    List<ScriptureReflection> reflections,
    bool hasSubmitted,
    String uid,
  ) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('REFLECTIONS (${reflections.length})'.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
        const Spacer(),
        if (!hasSubmitted)
          GestureDetector(
            onTap: () => _showSubmitReflectionSheet(context, focus.id, uid),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: MyWalkColor.golden.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Add Reflection',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MyWalkColor.golden)),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      if (reflections.isEmpty)
        Text('No reflections yet. Be the first to share.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.35)))
      else
        ...reflections.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ReflectionCard(reflection: r, uid: uid),
        )),
    ]);
  }

  void _showSetFocusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => SetScriptureFocusSheet(circleId: circleId),
    );
  }

  void _showSubmitReflectionSheet(BuildContext context, String weekId, String uid) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => _SubmitReflectionSheet(
        circleId: circleId, weekId: weekId, uid: uid),
    );
  }
}

// ─── Focus Card ───────────────────────────────────────────────────────────────

class _FocusCard extends StatelessWidget {
  final ScriptureFocus focus;
  const _FocusCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.menu_book_rounded, size: 14, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          Text('${focus.reference}  •  ${focus.translation}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.golden)),
          const Spacer(),
          Text('Set by ${focus.setByDisplayName}',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
        ]),
        const SizedBox(height: 12),
        Text(focus.text,
            style: TextStyle(
              fontSize: 15,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
              height: 1.6,
              fontStyle: FontStyle.italic,
            )),
        if (focus.reflectionPrompt != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MyWalkColor.inputBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.help_outline_rounded, size: 14,
                  color: MyWalkColor.softGold.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(child: Text(focus.reflectionPrompt!,
                  style: TextStyle(fontSize: 13, color: MyWalkColor.softGold.withValues(alpha: 0.8), height: 1.45))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Reflection Card ──────────────────────────────────────────────────────────

class _ReflectionCard extends StatelessWidget {
  final ScriptureReflection reflection;
  final String uid;
  const _ReflectionCard({required this.reflection, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isMe = reflection.isAuthor(uid);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(isMe ? 'You' : reflection.authorDisplayName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isMe ? MyWalkColor.golden : MyWalkColor.softGold)),
          const Spacer(),
          Text(_relativeTime(reflection.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(height: 6),
        Text(reflection.reflectionText,
            style: TextStyle(fontSize: 14, color: MyWalkColor.warmWhite.withValues(alpha: 0.9), height: 1.45)),
      ]),
    );
  }

  String _relativeTime(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Submit Reflection Sheet ──────────────────────────────────────────────────

class _SubmitReflectionSheet extends StatefulWidget {
  final String circleId;
  final String weekId;
  final String uid;
  const _SubmitReflectionSheet(
      {required this.circleId, required this.weekId, required this.uid});

  @override
  State<_SubmitReflectionSheet> createState() => _SubmitReflectionSheetState();
}

class _SubmitReflectionSheetState extends State<_SubmitReflectionSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
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
          const Text('Share Your Reflection',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
          const SizedBox(height: 4),
          Text('What spoke to you from this passage?',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLength: 300,
            maxLines: 4,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write your reflection…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true, fillColor: MyWalkColor.inputBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          const SizedBox(height: 12),
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
                  : const Text('Share Reflection',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) { setState(() => _error = 'Please write a reflection.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<ScriptureFocusProvider>().submitReflection(
        circleId: widget.circleId, weekId: widget.weekId, text: text,
        uid: widget.uid,
        displayName: AuthService.shared.displayName ?? 'Circle Member',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}

// ─── Set Scripture Focus Sheet ────────────────────────────────────────────────

class SetScriptureFocusSheet extends StatefulWidget {
  final String circleId;
  const SetScriptureFocusSheet({super.key, required this.circleId});

  @override
  State<SetScriptureFocusSheet> createState() => _SetScriptureFocusSheetState();
}

class _SetScriptureFocusSheetState extends State<SetScriptureFocusSheet> {
  final _refController = TextEditingController();
  final _textController = TextEditingController();
  final _promptController = TextEditingController();
  String _translation = 'NIV';
  bool _fetching = false;
  bool _submitting = false;
  String? _error;

  static const _translations = ['NIV', 'ESV', 'KJV', 'NLT', 'WEB'];

  @override
  void dispose() {
    _refController.dispose();
    _textController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Set Scripture Focus',
            style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.golden))
                : const Text('Set', style: TextStyle(color: MyWalkColor.golden, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16,
            MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Reference'),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _refController,
                style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
                decoration: _inputDec('e.g. John 3:16'),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _translation,
              dropdownColor: MyWalkColor.cardBackground,
              style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 13),
              underline: const SizedBox(),
              items: _translations.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _translation = v ?? 'NIV'),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _fetchPassage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _fetching
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: MyWalkColor.golden))
                    : const Text('Fetch', style: TextStyle(fontSize: 13, color: MyWalkColor.golden)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _label('Passage Text'),
          const SizedBox(height: 6),
          TextField(
            controller: _textController,
            maxLines: 6,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('Paste or type the passage text…'),
          ),
          const SizedBox(height: 14),
          _label('Reflection Prompt (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _promptController,
            maxLength: 200,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: _inputDec('e.g. What does this verse mean for your week?'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: MyWalkColor.warmCoral)),
          ],
        ]),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5)));
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
    filled: true, fillColor: MyWalkColor.inputBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
  );

  Future<void> _fetchPassage() async {
    final ref = _refController.text.trim();
    if (ref.isEmpty) return;
    setState(() { _fetching = true; _error = null; });
    try {
      final text = await context.read<ScriptureFocusProvider>()
          .fetchPassagePreview(ref, _translation);
      if (text.isNotEmpty && mounted) {
        _textController.text = text;
      } else if (mounted) {
        setState(() => _error = 'Passage not found. You can type it manually.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not fetch passage. Type it manually.');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _submit() async {
    final ref = _refController.text.trim();
    final text = _textController.text.trim();
    if (ref.isEmpty) { setState(() => _error = 'Reference required.'); return; }
    if (text.isEmpty) { setState(() => _error = 'Passage text required.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await context.read<ScriptureFocusProvider>().setFocus(
        circleId: widget.circleId,
        reference: ref,
        translation: _translation,
        passageText: text,
        reflectionPrompt: _promptController.text.trim().isEmpty ? null : _promptController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }
}
