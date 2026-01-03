import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final String userId;
  final String text;
  final DateTime date;
  final DateTime timestamp;

  // AI Analysis fields (will be populated after analysis)
  final String? emotion;
  final double? confidenceScore;
  final DateTime? analyzedAt;
  final String? analysisStatus; // 'pending', 'completed', 'failed'

  MoodEntry({
    required this.id,
    required this.userId,
    required this.text,
    required this.date,
    required this.timestamp,
    this.emotion,
    this.confidenceScore,
    this.analyzedAt,
    this.analysisStatus = 'pending',
  });

  // Convert MoodEntry to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'text': text,
      'date': Timestamp.fromDate(date),
      'timestamp': Timestamp.fromDate(timestamp),
      'emotion': emotion,
      'confidenceScore': confidenceScore,
      'analyzedAt': analyzedAt != null ? Timestamp.fromDate(analyzedAt!) : null,
      'analysisStatus': analysisStatus,
    };
  }

  // Create MoodEntry from Firestore document
  factory MoodEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return MoodEntry(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      emotion: data['emotion'],
      confidenceScore: data['confidenceScore']?.toDouble(),
      analyzedAt: data['analyzedAt'] != null
          ? (data['analyzedAt'] as Timestamp).toDate()
          : null,
      analysisStatus: data['analysisStatus'] ?? 'pending',
    );
  }

  // Create a copy with updated fields
  MoodEntry copyWith({
    String? id,
    String? userId,
    String? text,
    DateTime? date,
    DateTime? timestamp,
    String? emotion,
    double? confidenceScore,
    DateTime? analyzedAt,
    String? analysisStatus,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      emotion: emotion ?? this.emotion,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      analysisStatus: analysisStatus ?? this.analysisStatus,
    );
  }
}
