import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportRequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
}

class SupportRequestModel {
  final String id;
  final String userId;
  final String? counsellorId;
  final String? message;
  final SupportRequestStatus status;
  final String? conversationThreadId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  SupportRequestModel({
    required this.id,
    required this.userId,
    this.counsellorId,
    this.message,
    this.status = SupportRequestStatus.pending,
    this.conversationThreadId,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.completedAt,
  });

  // Convert SupportRequestModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'counsellorId': counsellorId,
      'message': message,
      'status': status.name,
      'conversationThreadId': conversationThreadId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  // Create SupportRequestModel from Firestore document
  factory SupportRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return SupportRequestModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      counsellorId: data['counsellorId'],
      message: data['message'],
      status: _parseStatus(data['status']),
      conversationThreadId: data['conversationThreadId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Parse status string to enum
  static SupportRequestStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return SupportRequestStatus.pending;
      case 'accepted':
        return SupportRequestStatus.accepted;
      case 'inprogress':
        return SupportRequestStatus.inProgress;
      case 'completed':
        return SupportRequestStatus.completed;
      case 'cancelled':
        return SupportRequestStatus.cancelled;
      default:
        return SupportRequestStatus.pending;
    }
  }

  // Copy with method for updates
  SupportRequestModel copyWith({
    String? id,
    String? userId,
    String? counsellorId,
    String? message,
    SupportRequestStatus? status,
    String? conversationThreadId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return SupportRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      counsellorId: counsellorId ?? this.counsellorId,
      message: message ?? this.message,
      status: status ?? this.status,
      conversationThreadId: conversationThreadId ?? this.conversationThreadId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
