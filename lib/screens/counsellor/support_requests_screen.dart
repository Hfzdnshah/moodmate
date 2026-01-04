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
      appBar: AppBar(
        title: const Text('My Support Requests'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
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
            Icon(
              Icons.support_agent_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(SupportRequestModel request) {
    final colorScheme = Theme.of(context).colorScheme;
    final canCancel = request.status == SupportRequestStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: _getStatusColor(request.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusText(request.status),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ),
                if (canCancel)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () => _cancelRequest(request.id),
                    tooltip: 'Cancel Request',
                  ),
              ],
            ),
            const Divider(height: 32),
            if (request.message != null) ...[
              Text(
                'Message',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.message!,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(request.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (request.acceptedAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Accepted',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(request.acceptedAt!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (request.conversationThreadId != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () async {
                    try {
                      // Get conversation thread details
                      final threadDetails = await _messageService
                          .getConversationThread(request.conversationThreadId!);

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
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final otherUserId =
                          threadDetails['userId'] == currentUserId
                          ? threadDetails['counsellorId']
                          : threadDetails['userId'];

                      // Navigate to conversation
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConversationScreen(
                              conversationThreadId:
                                  request.conversationThreadId!,
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Conversation'),
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
