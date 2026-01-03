import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_request_model.dart';

class SupportRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'support_requests';

  // Create a new support request
  Future<String> createSupportRequest({
    required String userId,
    String? counsellorId,
    String? message,
  }) async {
    try {
      final now = DateTime.now();
      final supportRequest = SupportRequestModel(
        id: '', // Will be set by Firestore
        userId: userId,
        counsellorId: counsellorId,
        message: message,
        status: SupportRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(supportRequest.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create support request: $e');
    }
  }

  // Get support requests for a user
  Future<List<SupportRequestModel>> getUserSupportRequests(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SupportRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch support requests: $e');
    }
  }

  // Get support requests for a counsellor
  Future<List<SupportRequestModel>> getCounsellorSupportRequests(
    String counsellorId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('counsellorId', isEqualTo: counsellorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SupportRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch counsellor support requests: $e');
    }
  }

  // Get pending support requests (for any available counsellor)
  Future<List<SupportRequestModel>> getPendingSupportRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => SupportRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending support requests: $e');
    }
  }

  // Get a specific support request
  Future<SupportRequestModel?> getSupportRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return SupportRequestModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch support request: $e');
    }
  }

  // Stream support request updates
  Stream<SupportRequestModel?> streamSupportRequest(String requestId) {
    return _firestore
        .collection(_collectionName)
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }
          return SupportRequestModel.fromFirestore(snapshot);
        });
  }

  // Stream user's support requests
  Stream<List<SupportRequestModel>> streamUserSupportRequests(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Accept a support request (for counsellors)
  Future<void> acceptSupportRequest(
    String requestId,
    String counsellorId,
  ) async {
    try {
      final now = DateTime.now();
      await _firestore.collection(_collectionName).doc(requestId).update({
        'counsellorId': counsellorId,
        'status': SupportRequestStatus.accepted.name,
        'acceptedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Create a conversation thread
      await _createConversationThread(requestId, counsellorId);
    } catch (e) {
      throw Exception('Failed to accept support request: $e');
    }
  }

  // Create conversation thread
  Future<void> _createConversationThread(
    String requestId,
    String counsellorId,
  ) async {
    try {
      final request = await getSupportRequestById(requestId);
      if (request == null) {
        throw Exception('Support request not found');
      }

      final threadData = {
        'supportRequestId': requestId,
        'userId': request.userId,
        'counsellorId': counsellorId,
        'createdAt': Timestamp.now(),
        'lastMessageAt': Timestamp.now(),
      };

      final threadRef = await _firestore
          .collection('conversation_threads')
          .add(threadData);

      // Update support request with conversation thread ID
      await _firestore.collection(_collectionName).doc(requestId).update({
        'conversationThreadId': threadRef.id,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to create conversation thread: $e');
    }
  }

  // Update support request status
  Future<void> updateSupportRequestStatus(
    String requestId,
    SupportRequestStatus status,
  ) async {
    try {
      final updates = {'status': status.name, 'updatedAt': Timestamp.now()};

      if (status == SupportRequestStatus.completed) {
        updates['completedAt'] = Timestamp.now();
      }

      await _firestore
          .collection(_collectionName)
          .doc(requestId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update support request status: $e');
    }
  }

  // Cancel support request
  Future<void> cancelSupportRequest(String requestId) async {
    try {
      await updateSupportRequestStatus(
        requestId,
        SupportRequestStatus.cancelled,
      );
    } catch (e) {
      throw Exception('Failed to cancel support request: $e');
    }
  }

  // Check if user has pending support request
  Future<bool> hasPendingSupportRequest(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'inProgress'])
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check pending support request: $e');
    }
  }
}
