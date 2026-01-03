import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_entry_model.dart';

class MoodEntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'mood_entries';

  // Create a new mood entry
  Future<String> createMoodEntry({
    required String userId,
    required String text,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final entry = MoodEntry(
        id: '', // Will be set by Firestore
        userId: userId,
        text: text,
        date: today,
        timestamp: now,
        analysisStatus: 'pending',
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(entry.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create mood entry: $e');
    }
  }

  // Get mood entries for a specific user
  Future<List<MoodEntry>> getUserMoodEntries(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MoodEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch mood entries: $e');
    }
  }

  // Get mood entries for a specific date
  Future<List<MoodEntry>> getMoodEntriesByDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MoodEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch mood entries by date: $e');
    }
  }

  // Check if user has already made an entry today
  Future<bool> hasEntryToday(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(tomorrow))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check today\'s entry: $e');
    }
  }

  // Get a single mood entry by ID
  Future<MoodEntry?> getMoodEntry(String entryId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(entryId)
          .get();

      if (docSnapshot.exists) {
        return MoodEntry.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch mood entry: $e');
    }
  }

  // Stream mood entries for real-time updates
  Stream<List<MoodEntry>> streamUserMoodEntries(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList(),
        );
  }

  // Update mood entry (mainly for AI analysis results)
  Future<void> updateMoodEntry({
    required String entryId,
    String? emotion,
    double? confidenceScore,
    String? analysisStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (emotion != null) updateData['emotion'] = emotion;
      if (confidenceScore != null)
        updateData['confidenceScore'] = confidenceScore;
      if (analysisStatus != null) updateData['analysisStatus'] = analysisStatus;

      if (emotion != null || confidenceScore != null) {
        updateData['analyzedAt'] = Timestamp.now();
      }

      await _firestore
          .collection(_collectionName)
          .doc(entryId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update mood entry: $e');
    }
  }

  // Delete a mood entry
  Future<void> deleteMoodEntry(String entryId) async {
    try {
      await _firestore.collection(_collectionName).doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete mood entry: $e');
    }
  }
}
