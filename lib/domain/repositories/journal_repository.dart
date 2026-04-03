import '../entities/journal_entry.dart';

abstract class JournalRepository {
  /// Load all journal entries for the authenticated user, newest first.
  Future<List<JournalEntry>> loadEntries();

  /// Persist a new journal entry.
  Future<void> saveEntry(JournalEntry entry);

  /// Update an existing journal entry (merge — preserves fields not in [entry]).
  Future<void> updateEntry(JournalEntry entry);

  /// Delete a journal entry document. Storage media must be deleted separately.
  Future<void> deleteEntry(String id);

  /// Upload a local file to Firebase Storage and return its download URL.
  /// [entryId] and [filename] determine the storage path.
  Future<String> uploadMedia(String localPath, String entryId, String filename);

  /// Delete a Firebase Storage object by its download URL.
  Future<void> deleteMedia(String url);
}
