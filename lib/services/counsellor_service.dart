import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/counsellor_model.dart';

class CounsellorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'counsellors';

  // Get all available counsellors
  Future<List<CounsellorModel>> getAvailableCounsellors() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'available')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => CounsellorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available counsellors: $e');
    }
  }

  // Get all counsellors (for admin purposes)
  Future<List<CounsellorModel>> getAllCounsellors() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => CounsellorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch counsellors: $e');
    }
  }

  // Get counsellor by ID
  Future<CounsellorModel?> getCounsellorById(String counsellorId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(counsellorId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return CounsellorModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch counsellor: $e');
    }
  }

  // Stream counsellor status updates
  Stream<CounsellorModel?> streamCounsellor(String counsellorId) {
    return _firestore
        .collection(_collectionName)
        .doc(counsellorId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }
          return CounsellorModel.fromFirestore(snapshot);
        });
  }

  // Update counsellor status (for counsellors to update their own status)
  Future<void> updateCounsellorStatus(
    String counsellorId,
    CounsellorStatus status,
  ) async {
    try {
      await _firestore.collection(_collectionName).doc(counsellorId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update counsellor status: $e');
    }
  }

  // Create counsellor profile (admin only)
  Future<String> createCounsellorProfile({
    required String userId,
    required String name,
    required String email,
    String? specialization,
    String? bio,
    List<String>? availableHours,
    int? yearsOfExperience,
  }) async {
    try {
      final now = DateTime.now();
      final counsellor = CounsellorModel(
        id: userId, // Use the user's UID as counsellor ID
        name: name,
        email: email,
        specialization: specialization,
        bio: bio,
        status: CounsellorStatus.available,
        availableHours: availableHours ?? [],
        yearsOfExperience: yearsOfExperience,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(counsellor.toFirestore());

      return userId;
    } catch (e) {
      throw Exception('Failed to create counsellor profile: $e');
    }
  }

  // Update counsellor profile
  Future<void> updateCounsellorProfile(
    String counsellorId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(_collectionName)
          .doc(counsellorId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update counsellor profile: $e');
    }
  }

  // Search counsellors by specialization
  Future<List<CounsellorModel>> searchCounsellorsBySpecialization(
    String specialization,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('specialization', isEqualTo: specialization)
          .where('status', isEqualTo: 'available')
          .get();

      return querySnapshot.docs
          .map((doc) => CounsellorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search counsellors: $e');
    }
  }
}
