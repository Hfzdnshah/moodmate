import 'package:cloud_firestore/cloud_firestore.dart';

enum CounsellorStatus { available, busy, offline }

class CounsellorModel {
  final String id;
  final String name;
  final String email;
  final String? specialization;
  final String? bio;
  final CounsellorStatus status;
  final List<String> availableHours;
  final int? yearsOfExperience;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CounsellorModel({
    required this.id,
    required this.name,
    required this.email,
    this.specialization,
    this.bio,
    this.status = CounsellorStatus.available,
    this.availableHours = const [],
    this.yearsOfExperience,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert CounsellorModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'specialization': specialization,
      'bio': bio,
      'status': status.name,
      'availableHours': availableHours,
      'yearsOfExperience': yearsOfExperience,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create CounsellorModel from Firestore document
  factory CounsellorModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return CounsellorModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      specialization: data['specialization'],
      bio: data['bio'],
      status: _parseStatus(data['status']),
      availableHours: List<String>.from(data['availableHours'] ?? []),
      yearsOfExperience: data['yearsOfExperience'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Parse role string to enum
  static CounsellorStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return CounsellorStatus.available;
      case 'busy':
        return CounsellorStatus.busy;
      case 'offline':
        return CounsellorStatus.offline;
      default:
        return CounsellorStatus.available;
    }
  }

  // Copy with method for updates
  CounsellorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? specialization,
    String? bio,
    CounsellorStatus? status,
    List<String>? availableHours,
    int? yearsOfExperience,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CounsellorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      availableHours: availableHours ?? this.availableHours,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
