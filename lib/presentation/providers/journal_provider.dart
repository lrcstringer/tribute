import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/media_upload_service.dart';
import '../../domain/entities/fruit.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';

enum JournalSortOrder { newestFirst, oldestFirst, byHabit, byFruit }

class JournalProvider extends ChangeNotifier {
  final JournalRepository _repository;

  JournalProvider(this._repository) {
    // Register upload-completion callback so the UI reflects finished uploads.
    MediaUploadService.instance.registerEntryUpdatedCallback(refreshEntry);
    AuthService.shared.addListener(_onAuthChanged);
  }

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  bool _loadInProgress = false;
  String _searchQuery = '';
  JournalSortOrder _sortOrder = JournalSortOrder.newestFirst;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  JournalSortOrder get sortOrder => _sortOrder;

  @override
  void dispose() {
    AuthService.shared.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (AuthService.shared.isAuthenticated) {
      loadEntries();
    } else {
      _entries = [];
      _isLoading = false;
      _loadInProgress = false;
      notifyListeners();
    }
  }

  /// Returns the entry with [id] from the raw (unfiltered) list, or null.
  JournalEntry? getEntry(String id) =>
      _entries.where((e) => e.id == id).firstOrNull;

  List<JournalEntry> get filteredEntries {
    var result = List<JournalEntry>.from(_entries);

    // Apply search filter.
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        final textMatch = e.text?.toLowerCase().contains(q) ?? false;
        final habitMatch = e.habitName?.toLowerCase().contains(q) ?? false;
        final fruitMatch = e.fruitTag?.label.toLowerCase().contains(q) ?? false;
        return textMatch || habitMatch || fruitMatch;
      }).toList();
    }

    // Apply sort — all multi-key sorts use createdAt descending as stable tiebreaker.
    switch (_sortOrder) {
      case JournalSortOrder.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case JournalSortOrder.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case JournalSortOrder.byHabit:
        result.sort((a, b) {
          final primary = (a.habitName ?? '').compareTo(b.habitName ?? '');
          return primary != 0 ? primary : b.createdAt.compareTo(a.createdAt);
        });
      case JournalSortOrder.byFruit:
        result.sort((a, b) {
          final primary =
              (a.fruitTag?.label ?? '').compareTo(b.fruitTag?.label ?? '');
          return primary != 0 ? primary : b.createdAt.compareTo(a.createdAt);
        });
    }

    return result;
  }

  Future<void> loadEntries() async {
    if (_loadInProgress) return;
    _loadInProgress = true;
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _repository.loadEntries();
    } catch (_) {
      // Leave existing entries in place on error.
    } finally {
      _isLoading = false;
      _loadInProgress = false;
      notifyListeners();
    }
  }

  /// Save a new journal entry.
  ///
  /// Media files ([imageLocalPaths], [voiceLocalPath]) are copied to a stable
  /// app-documents directory and queued for upload via [MediaUploadService].
  Future<void> saveEntry({
    String? text,
    List<String> imageLocalPaths = const [],
    String? voiceLocalPath,
    String? habitId,
    String? habitName,
    FruitType? fruitTag,
    required String sourceType,
  }) async {
    final hasPendingMedia = imageLocalPaths.isNotEmpty || voiceLocalPath != null;

    final entry = JournalEntry.create(
      text: text,
      imageUrls: const [],
      voiceUrl: null,
      uploadPending: hasPendingMedia,
      habitId: habitId,
      habitName: habitName,
      fruitTag: fruitTag,
      sourceType: sourceType,
    );

    // Copy media to stable local paths before saving.
    final pendingFiles = await _stageMediaFiles(entry.id, imageLocalPaths, voiceLocalPath);

    await _repository.saveEntry(entry);

    _entries = [entry, ..._entries];
    notifyListeners();

    if (pendingFiles.isNotEmpty) {
      await MediaUploadService.instance.enqueueUploads(entry.id, pendingFiles);
    }
  }

  /// Update an existing journal entry's text and/or add/remove media.
  ///
  /// Pass [clearText] = true to explicitly set the text field to null (empty).
  /// If [text] is null and [clearText] is false, the existing text is preserved.
  Future<void> updateEntry(
    JournalEntry entry, {
    String? text,
    bool clearText = false,
    List<String> newImageLocalPaths = const [],
    String? newVoiceLocalPath,
    List<String>? removedImageUrls,
    bool? removeVoice,
  }) async {
    final hasPendingMedia = newImageLocalPaths.isNotEmpty || newVoiceLocalPath != null;

    // Delete removed media from Storage (fire-and-forget).
    if (removedImageUrls != null) {
      for (final url in removedImageUrls) {
        _repository.deleteMedia(url).ignore();
      }
    }
    if (removeVoice == true && entry.voiceUrl != null) {
      _repository.deleteMedia(entry.voiceUrl!).ignore();
    }

    final updatedImageUrls = removedImageUrls != null
        ? entry.imageUrls.where((u) => !removedImageUrls.contains(u)).toList()
        : entry.imageUrls;

    // Build updated entry directly to support explicit text clearing.
    // JournalEntry.copyWith cannot set text to null (no sentinel), so we
    // construct the entry here when clearText is needed.
    final resolvedText = clearText ? null : (text ?? entry.text);
    final updated = JournalEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
      text: resolvedText,
      imageUrls: updatedImageUrls,
      voiceUrl: removeVoice == true ? null : entry.voiceUrl,
      uploadPending: hasPendingMedia,
      habitId: entry.habitId,
      habitName: entry.habitName,
      fruitTag: entry.fruitTag,
      sourceType: entry.sourceType,
    );

    final pendingFiles =
        await _stageMediaFiles(entry.id, newImageLocalPaths, newVoiceLocalPath);

    await _repository.updateEntry(updated);

    _entries = [
      for (final e in _entries) e.id == updated.id ? updated : e,
    ];
    notifyListeners();

    if (pendingFiles.isNotEmpty) {
      await MediaUploadService.instance.enqueueUploads(entry.id, pendingFiles);
    }
  }

  /// Delete a journal entry and all its Storage media.
  Future<void> deleteEntry(JournalEntry entry) async {
    // Delete Storage media (fire-and-forget).
    for (final url in entry.imageUrls) {
      _repository.deleteMedia(url).ignore();
    }
    if (entry.voiceUrl != null) {
      _repository.deleteMedia(entry.voiceUrl!).ignore();
    }

    await _repository.deleteEntry(entry.id);

    _entries = _entries.where((e) => e.id != entry.id).toList();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOrder(JournalSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  /// Called by [MediaUploadService] after successful uploads to refresh entry state.
  Future<void> refreshEntry(String entryId) async {
    try {
      final all = await _repository.loadEntries();
      final refreshed = all.where((e) => e.id == entryId).firstOrNull;
      if (refreshed != null) {
        _entries = [
          for (final e in _entries) e.id == entryId ? refreshed : e,
        ];
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Copies media files to a stable app-documents subdirectory so the paths
  /// survive across sessions. Returns the list of [PendingMediaFile] items.
  Future<List<PendingMediaFile>> _stageMediaFiles(
    String entryId,
    List<String> imageLocalPaths,
    String? voiceLocalPath,
  ) async {
    if (imageLocalPaths.isEmpty && voiceLocalPath == null) return [];

    final appDir = await getApplicationDocumentsDirectory();
    final entryDir = Directory('${appDir.path}/journal/$entryId');
    await entryDir.create(recursive: true);

    final pending = <PendingMediaFile>[];

    for (var i = 0; i < imageLocalPaths.length; i++) {
      final src = File(imageLocalPaths[i]);
      if (!src.existsSync()) continue;
      final dest = '${entryDir.path}/image_$i.jpg';
      await src.copy(dest);
      pending.add(PendingMediaFile(type: 'image', localPath: dest, index: i));
    }

    if (voiceLocalPath != null) {
      final src = File(voiceLocalPath);
      if (src.existsSync()) {
        final dest = '${entryDir.path}/voice.m4a';
        await src.copy(dest);
        pending.add(PendingMediaFile(type: 'voice', localPath: dest, index: -1));
      }
    }

    return pending;
  }
}
