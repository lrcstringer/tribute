import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';

/// Firestore-backed implementation of [HabitRepository].
///
/// Data layout:
///   users/{uid}/habits/{habitId}          — habit metadata + lifetime aggregates
///   users/{uid}/habits/{habitId}/entries/{YYYY-MM-DD}  — daily entry
///
/// Aggregates (allTimeCompletedCount, allTimeTotalValue) are maintained atomically
/// via Firestore transactions on every [upsertEntry] call.
///
/// Only entries from the last [_entryWindowDays] days are loaded to keep
/// memory usage bounded; lifetime stats come from the aggregate fields.
class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _db;

  /// How many days of entries to load for display (current week + retroactive window).
  static const int _entryWindowDays = 28;

  FirestoreHabitRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('FirestoreHabitRepository: no authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      _db.collection('users').doc(_uid).collection('habits');

  CollectionReference<Map<String, dynamic>> _entriesRef(String habitId) =>
      _habitsRef.doc(habitId).collection('entries');

  // ── HabitRepository interface ─────────────────────────────────────────────

  @override
  Future<List<Habit>> loadHabits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];

    final habitsSnap = await _habitsRef.orderBy('sortOrder').get();
    if (habitsSnap.docs.isEmpty) return const [];

    // Load entries for the last _entryWindowDays days in parallel.
    final cutoffDate = DateTime.now().subtract(const Duration(days: _entryWindowDays));
    final cutoffKey = HabitEntry.dateKey(cutoffDate);

    final entryFutures = habitsSnap.docs.map((doc) async {
      final entriesSnap = await _entriesRef(doc.id)
          .where('date', isGreaterThanOrEqualTo: cutoffKey)
          .get();
      return entriesSnap.docs
          .map((e) => HabitEntry.fromFirestore(e.data()))
          .toList();
    });

    final entriesList = await Future.wait(entryFutures);

    return List.generate(habitsSnap.docs.length, (i) {
      final data = habitsSnap.docs[i].data();
      return Habit.fromFirestore(data, entries: entriesList[i]);
    }).where((h) => !h.isArchived).toList();
  }

  @override
  Future<void> insertHabit(Habit habit) async {
    await _habitsRef.doc(habit.id).set(habit.toFirestore());
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    // Use merge so we don't accidentally wipe aggregate counters if the caller
    // didn't populate them.
    await _habitsRef.doc(habit.id).set(habit.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    // Delete all entries in the subcollection first (Firestore doesn't cascade).
    await _deleteSubcollection(_entriesRef(habitId));
    await _habitsRef.doc(habitId).delete();
  }

  @override
  Future<void> upsertEntry(HabitEntry entry) async {
    final entryKey = HabitEntry.dateKey(entry.date);
    final entryRef = _entriesRef(entry.habitId).doc(entryKey);
    final habitRef = _habitsRef.doc(entry.habitId);

    await _db.runTransaction((tx) async {
      final existingSnap = await tx.get(entryRef);
      final existing = existingSnap.exists && existingSnap.data() != null
          ? HabitEntry.fromFirestore(existingSnap.data()!)
          : null;

      final prevCompleted = (existing?.isCompleted ?? false) ? 1 : 0;
      final prevValue = existing?.value ?? 0.0;

      final deltaCompleted = (entry.isCompleted ? 1 : 0) - prevCompleted;
      final deltaValue = entry.value - prevValue;

      tx.set(entryRef, entry.toFirestore());

      if (deltaCompleted != 0 || deltaValue != 0.0) {
        tx.update(habitRef, {
          'allTimeCompletedCount': FieldValue.increment(deltaCompleted),
          'allTimeTotalValue': FieldValue.increment(deltaValue),
        });
      }
    });
  }

  @override
  Future<void> setArchived(String habitId, {required bool archived}) async {
    await _habitsRef.doc(habitId).update({'isArchived': archived});
  }

  @override
  Future<List<Habit>> loadArchivedHabits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    final snap = await _habitsRef.where('isArchived', isEqualTo: true).get();
    return snap.docs.map((d) => Habit.fromFirestore(d.data())).toList();
  }

  @override
  Future<void> clearHabitEntries(String habitId) async {
    await _deleteSubcollection(_entriesRef(habitId));
    await _habitsRef.doc(habitId).update({
      'allTimeCompletedCount': 0,
      'allTimeTotalValue': 0.0,
    });
  }

  @override
  Future<void> updateHabitSortOrders(List<Habit> habits) async {
    final batch = _db.batch();
    for (final habit in habits) {
      batch.update(_habitsRef.doc(habit.id), {'sortOrder': habit.sortOrder});
    }
    await batch.commit();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Deletes all documents in a subcollection in batches of 100.
  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    const batchSize = 100;
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await ref.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == batchSize);
  }
}
