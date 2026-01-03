import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message in a conversation thread
  Future<String> sendMessage({
    required String conversationThreadId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final message = MessageModel(
        id: '', // Will be set by Firestore
        conversationThreadId: conversationThreadId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      final docRef = await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .collection('messages')
          .add(message.toFirestore());

      // Update conversation thread's lastMessageAt
      await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .update({'lastMessageAt': Timestamp.now()});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a conversation thread
  Future<List<MessageModel>> getMessages(String conversationThreadId) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Stream messages for real-time updates
  Stream<List<MessageModel>> streamMessages(String conversationThreadId) {
    return _firestore
        .collection('conversation_threads')
        .doc(conversationThreadId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Mark message as read
  Future<void> markMessageAsRead(
    String conversationThreadId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true, 'readAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Mark all messages as read for a user
  Future<void> markAllMessagesAsRead(
    String conversationThreadId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  // Get unread message count for a user in a conversation
  Future<int> getUnreadMessageCount(
    String conversationThreadId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  // Delete a message (soft delete by updating content)
  Future<void> deleteMessage(
    String conversationThreadId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .collection('messages')
          .doc(messageId)
          .update({'content': '[Message deleted]'});
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Get conversation thread by support request
  Future<String?> getConversationThreadIdByRequestId(
    String supportRequestId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversation_threads')
          .where('supportRequestId', isEqualTo: supportRequestId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.id;
    } catch (e) {
      throw Exception('Failed to get conversation thread: $e');
    }
  }

  // Get conversation thread details
  Future<Map<String, dynamic>?> getConversationThread(
    String conversationThreadId,
  ) async {
    try {
      final doc = await _firestore
          .collection('conversation_threads')
          .doc(conversationThreadId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return doc.data();
    } catch (e) {
      throw Exception('Failed to get conversation thread details: $e');
    }
  }
}
