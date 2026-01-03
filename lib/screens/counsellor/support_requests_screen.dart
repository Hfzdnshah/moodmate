import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/support_request_model.dart';
import '../../services/support_request_service.dart';
import '../../services/message_service.dart';
import 'conversation_screen.dart';
import 'dart:async';

class SupportRequestsScreen extends StatefulWidget {
  const SupportRequestsScreen({super.key});

  @override
  State<SupportRequestsScreen> createState() => _SupportRequestsScreenState();
}

class _SupportRequestsScreenState extends State<SupportRequestsScreen> {
  final SupportRequestService _supportRequestService = SupportRequestService();
  final MessageService _messageService = MessageService();
  StreamSubscription<List<SupportRequestModel>>? _requestsSubscription;
  List<SupportRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _listenToSupportRequests();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void _listenToSupportRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view your support requests';
        _isLoading = false;
      });
      return;
    }

    _requestsSubscription = _supportRequestService
        .streamUserSupportRequests(user.uid)
        .listen(
          (requests) {
            setState(() {
              _requests = requests;
              _isLoading = false;
              _errorMessage = null;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          },
        );
  }

  String _getStatusText(SupportRequestStatus status) {
    switch (status) {
      case SupportRequestStatus.pending:
        return 'Pending';
      case SupportRequestStatus.accepted:
        return 'Accepted';
      case SupportRequestStatus.inProgress:
        return 'In Progress';
      case SupportRequestStatus.completed:
        return 'Completed';
      case SupportRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(SupportRequestStatus status) {
    switch (status) {
      case SupportRequestStatus.pending:
        return Colors.orange;
      case SupportRequestStatus.accepted:
        return Colors.blue;
      case SupportRequestStatus.inProgress:
        return Colors.purple;
      case SupportRequestStatus.completed:
        return Colors.green;
      case SupportRequestStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(SupportRequestStatus status) {
    switch (status) {
      case SupportRequestStatus.pending:
        return Icons.hourglass_empty;
      case SupportRequestStatus.accepted:
        return Icons.check_circle_outline;
      case SupportRequestStatus.inProgress:
        return Icons.autorenew;
      case SupportRequestStatus.completed:
        return Icons.done_all;
      case SupportRequestStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this support request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supportRequestService.cancelSupportRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support request cancelled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Support Requests')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load support requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No support requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Contact a counsellor to get started.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(SupportRequestModel request) {
    final canCancel = request.status == SupportRequestStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(request.status),
                  color: _getStatusColor(request.status),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusText(request.status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ),
                if (canCancel)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelRequest(request.id),
                    tooltip: 'Cancel Request',
                  ),
              ],
            ),
            const Divider(height: 24),
            if (request.message != null) ...[
              Text(
                'Message:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(request.message!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created:',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(request.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (request.acceptedAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Accepted:',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDate(request.acceptedAt!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (request.conversationThreadId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Get conversation thread details
                      final threadDetails = await _messageService.getConversationThread(
                        request.conversationThreadId!,
                      );

                      if (threadDetails == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Conversation thread not found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      // Determine other user
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final otherUserId = threadDetails['userId'] == currentUserId
                          ? threadDetails['counsellorId']
                          : threadDetails['userId'];

                      // Navigate to conversation
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConversationScreen(
                              conversationThreadId: request.conversationThreadId!,
                              otherUserId: otherUserId,
                              otherUserName: 'Chat',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('View Conversation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
