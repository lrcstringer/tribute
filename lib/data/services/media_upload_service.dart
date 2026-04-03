import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/journal_repository.dart';

/// Describes a single local media file waiting to be uploaded.
class PendingMediaFile {
  final String type;       // 'image' | 'voice'
  final String localPath;
  final int index;         // image index (0-based); -1 for voice

  const PendingMediaFile({
    required this.type,
    required this.localPath,
    required this.index,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'localPath': localPath,
        'index': index,
      };

  factory PendingMediaFile.fromJson(Map<String, dynamic> j) => PendingMediaFile(
        type: j['type'] as String,
        localPath: j['localPath'] as String,
        index: (j['index'] as num).toInt(),
      );
}

class _PendingEntry {
  final String entryId;
  final List<PendingMediaFile> files;

  _PendingEntry({required this.entryId, required this.files});

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'files': files.map((f) => f.toJson()).toList(),
      };

  factory _PendingEntry.fromJson(Map<String, dynamic> j) => _PendingEntry(
        entryId: j['entryId'] as String,
        files: (j['files'] as List)
            .map((f) => PendingMediaFile.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
      );
}

/// Manages offline-first media uploads for journal entries.
///
/// When a journal entry is saved with images or a voice note while offline,
/// the media files are stored locally and their paths are queued here.
/// This service processes the queue when connectivity is restored.
class MediaUploadService {
  MediaUploadService._();
  static final instance = MediaUploadService._();

  static const _queueKey = 'journal_upload_queue';

  late SharedPreferences _prefs;
  late JournalRepository _repo;

  /// Called after each entry's uploads are committed to Firestore.
  void Function(String entryId)? _onEntryUpdated;

  bool _processing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> init(SharedPreferences prefs, JournalRepository repo) async {
    _prefs = prefs;
    _repo = repo;

    // Listen for connectivity changes and process queue when online.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) unawaited(processQueue());
    });

    // Process any leftover queue from a previous session.
    unawaited(processQueue());
  }

  /// Register a callback invoked after each entry's media is successfully
  /// uploaded and committed to Firestore. Used by [JournalProvider] to keep
  /// its in-memory state in sync without a direct cross-layer dependency.
  void registerEntryUpdatedCallback(void Function(String entryId) callback) {
    _onEntryUpdated = callback;
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Enqueue media files for a journal entry and start processing immediately.
  Future<void> enqueueUploads(String entryId, List<PendingMediaFile> files) async {
    if (files.isEmpty) return;
    final queue = _loadQueue();
    // Replace any existing entry for this id (e.g. re-save after edit).
    queue.removeWhere((e) => e.entryId == entryId);
    queue.add(_PendingEntry(entryId: entryId, files: files));
    _saveQueue(queue);
    unawaited(processQueue());
  }

  /// Process all pending uploads. Safe to call concurrently — only one run at a time.
  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = _loadQueue();
      if (queue.isEmpty) return;

      // Check connectivity first.
      final results = await Connectivity().checkConnectivity();
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) return;

      for (final pending in List.of(queue)) {
        await _processEntry(pending, queue);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _processEntry(_PendingEntry pending, List<_PendingEntry> queue) async {
    // Track files uploaded to Storage this run (but not yet committed to Firestore).
    // Local files are NOT deleted until the Firestore write succeeds.
    final uploaded = <({PendingMediaFile file, String url})>[];
    final stillPending = List<PendingMediaFile>.from(pending.files);

    for (final file in List.of(stillPending)) {
      if (!File(file.localPath).existsSync()) {
        // Local file missing (e.g. user uninstalled + reinstalled) — drop silently.
        stillPending.remove(file);
        continue;
      }
      try {
        final filename = file.type == 'voice'
            ? 'voice.m4a'
            : 'image_${file.index}.jpg';
        final url = await _repo.uploadMedia(file.localPath, pending.entryId, filename);
        uploaded.add((file: file, url: url));
      } catch (_) {
        // Upload failed — stop processing this entry; retry on next queue run.
        break;
      }
    }

    if (uploaded.isEmpty) {
      // Nothing uploaded — just sync queue state (e.g. dropped missing files).
      _commitQueue(queue, pending.entryId, stillPending);
      return;
    }

    // Attempt to commit uploaded URLs to Firestore.
    // IMPORTANT: local files are only deleted after this succeeds, so a failed
    // Firestore write does not result in orphaned Storage objects.
    bool committed = false;
    try {
      final entries = await _repo.loadEntries();
      final current = entries.where((e) => e.id == pending.entryId).firstOrNull;
      if (current != null) {
        final newImages = uploaded
            .where((u) => u.file.type == 'image')
            .map((u) => u.url)
            .toList();
        final newVoice = uploaded
            .where((u) => u.file.type == 'voice')
            .map((u) => u.url)
            .firstOrNull;
        // Files remaining after this commit = stillPending minus uploaded.
        final afterCommit = stillPending
            .where((f) => !uploaded.any((u) => u.file.localPath == f.localPath))
            .toList();
        final updated = current.copyWith(
          imageUrls: [...current.imageUrls, ...newImages],
          voiceUrl: newVoice ?? current.voiceUrl,
          uploadPending: afterCommit.isNotEmpty,
        );
        await _repo.updateEntry(updated);
      }
      // Entry deleted between save and upload — no Firestore doc to update;
      // treat as committed so we don't retry indefinitely.
      committed = true;
    } catch (_) {
      // Firestore write failed — local files are NOT deleted here; will retry.
    }

    if (committed) {
      // Safe to clean up local staging files now.
      for (final (:file, url: _) in uploaded) {
        try { File(file.localPath).deleteSync(); } catch (_) {}
        stillPending.remove(file);
      }
      _onEntryUpdated?.call(pending.entryId);
    }
    // If not committed, stillPending still holds the uploaded files → will retry,
    // re-uploading to Storage (same filename = overwrite), then retry Firestore.

    _commitQueue(queue, pending.entryId, stillPending);
  }

  void _commitQueue(
      List<_PendingEntry> queue, String entryId, List<PendingMediaFile> remaining) {
    queue.removeWhere((e) => e.entryId == entryId);
    if (remaining.isNotEmpty) {
      queue.add(_PendingEntry(entryId: entryId, files: remaining));
    }
    _saveQueue(queue);
  }

  List<_PendingEntry> _loadQueue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => _PendingEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _saveQueue(List<_PendingEntry> queue) {
    _prefs.setString(_queueKey, jsonEncode(queue.map((e) => e.toJson()).toList()));
  }
}

void unawaited(Future<void> future) {
  future.ignore();
}
