import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/counsellor_model.dart';
import '../../services/support_request_service.dart';

class CounsellorDetailScreen extends StatefulWidget {
  final CounsellorModel counsellor;

  const CounsellorDetailScreen({super.key, required this.counsellor});

  @override
  State<CounsellorDetailScreen> createState() => _CounsellorDetailScreenState();
}

class _CounsellorDetailScreenState extends State<CounsellorDetailScreen> {
  final SupportRequestService _supportRequestService = SupportRequestService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasPendingRequest = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkPendingRequest();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkPendingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final hasPending = await _supportRequestService.hasPendingSupportRequest(
        user.uid,
      );
      setState(() {
        _hasPendingRequest = hasPending;
        _isCheckingStatus = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  String _getStatusText(CounsellorStatus status) {
    switch (status) {
      case CounsellorStatus.available:
        return 'Available';
      case CounsellorStatus.busy:
        return 'Busy';
      case CounsellorStatus.offline:
        return 'Offline';
    }
  }

  Color _getStatusColor(CounsellorStatus status) {
    switch (status) {
      case CounsellorStatus.available:
        return Colors.green;
      case CounsellorStatus.busy:
        return Colors.orange;
      case CounsellorStatus.offline:
        return Colors.grey;
    }
  }

  Future<void> _submitSupportRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to request support'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _supportRequestService.createSupportRequest(
        userId: user.uid,
        counsellorId: widget.counsellor.id,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counsellor Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Profile
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    backgroundImage: widget.counsellor.profileImageUrl != null
                        ? NetworkImage(widget.counsellor.profileImageUrl!)
                        : null,
                    child: widget.counsellor.profileImageUrl == null
                        ? Text(
                            widget.counsellor.name.isNotEmpty
                                ? widget.counsellor.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.counsellor.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.counsellor.specialization != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.counsellor.specialization!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        widget.counsellor.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(widget.counsellor.status),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _getStatusText(widget.counsellor.status),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(widget.counsellor.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.counsellor.yearsOfExperience != null) ...[
                    _buildDetailItem(
                      icon: Icons.school,
                      title: 'Experience',
                      value: '${widget.counsellor.yearsOfExperience} years',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.counsellor.bio != null) ...[
                    _buildDetailItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      value: widget.counsellor.bio!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.counsellor.availableHours.isNotEmpty) ...[
                    _buildDetailItem(
                      icon: Icons.access_time,
                      title: 'Available Hours',
                      value: widget.counsellor.availableHours.join(', '),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDetailItem(
                    icon: Icons.email,
                    title: 'Email',
                    value: widget.counsellor.email,
                  ),
                  const SizedBox(height: 32),

                  // Request Support Section
                  if (_isCheckingStatus)
                    const Center(child: CircularProgressIndicator())
                  else if (_hasPendingRequest)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You already have a pending support request. Please wait for a response.',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Support',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Describe your situation and how this counsellor can help you.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Tell us how we can help...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _submitSupportRequest,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Submit Request',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
