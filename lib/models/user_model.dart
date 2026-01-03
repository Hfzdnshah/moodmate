import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, counsellor, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.emailVerified = false,
  });

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'emailVerified': emailVerified,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return UserModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: _parseRole(data['role']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      emailVerified: data['emailVerified'] ?? false,
    );
  }

  // Parse role string to UserRole enum
  static UserRole _parseRole(String? roleString) {
    switch (roleString) {
      case 'counsellor':
        return UserRole.counsellor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? emailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
