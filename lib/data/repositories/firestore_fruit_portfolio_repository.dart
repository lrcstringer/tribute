import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/fruit.dart';
import '../../domain/repositories/fruit_portfolio_repository.dart';

class FirestoreFruitPortfolioRepository implements FruitPortfolioRepository {
  final FirebaseFirestore _db;

  FirestoreFruitPortfolioRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('FirestoreFruitPortfolioRepository: no authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _portfolioRef =>
      _db.collection('users').doc(_uid).collection('fruit_portfolio');

  @override
  Future<FruitPortfolio> loadPortfolio() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return FruitPortfolio.empty();

    final snap = await _portfolioRef.get();
    final Map<FruitType, FruitPortfolioEntry> entries = {
      for (final f in FruitType.values) f: FruitPortfolioEntry(fruit: f),
    };

    for (final doc in snap.docs) {
      try {
        final entry = FruitPortfolioEntry.fromFirestore(doc.data());
        entries[entry.fruit] = entry;
      } catch (_) {
        // Skip malformed docs.
      }
    }

    return FruitPortfolio(entries: entries);
  }

  @override
  Future<void> updateOnCompletion(List<FruitType> fruits) async {
    if (fruits.isEmpty) return;
    final batch = _db.batch();
    final now = DateTime.now().toIso8601String();
    for (final fruit in fruits) {
      final ref = _portfolioRef.doc(fruit.name);
      batch.set(
        ref,
        {
          'fruit': fruit.name,
          'weeklyCompletions': FieldValue.increment(1),
          'totalCompletions': FieldValue.increment(1),
          'lastCompletedAt': now,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> resetPortfolio() async {
    const batchSize = 100;
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await _portfolioRef.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == batchSize);
  }

  @override
  Future<void> updateHabitCount(List<FruitType> fruits, int delta) async {
    if (fruits.isEmpty) return;
    final batch = _db.batch();
    for (final fruit in fruits) {
      final ref = _portfolioRef.doc(fruit.name);
      batch.set(
        ref,
        {
          'fruit': fruit.name,
          'habitCount': FieldValue.increment(delta),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
