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
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case CounsellorStatus.available:
        return colorScheme.tertiary;
      case CounsellorStatus.busy:
        return colorScheme.secondary;
      case CounsellorStatus.offline:
        return colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _submitSupportRequest() async {
    final colorScheme = Theme.of(context).colorScheme;

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a message')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to request support')),
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
          const SnackBar(content: Text('Support request submitted.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: colorScheme.error,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counsellor Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Profile
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: widget.counsellor.profileImageUrl != null
                          ? NetworkImage(widget.counsellor.profileImageUrl!)
                          : null,
                      child: widget.counsellor.profileImageUrl == null
                          ? Text(
                              widget.counsellor.name.isNotEmpty
                                  ? widget.counsellor.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
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
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
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
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.counsellor.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(widget.counsellor.status),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getStatusColor(widget.counsellor.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        if (widget.counsellor.yearsOfExperience != null) ...[
                          _buildDetailItem(
                            icon: Icons.school_rounded,
                            title: 'Experience',
                            value:
                                '${widget.counsellor.yearsOfExperience} years',
                          ),
                          const Divider(height: 32),
                        ],
                        if (widget.counsellor.bio != null) ...[
                          _buildDetailItem(
                            icon: Icons.info_outline_rounded,
                            title: 'Bio',
                            value: widget.counsellor.bio!,
                          ),
                          const Divider(height: 32),
                        ],
                        if (widget.counsellor.availableHours.isNotEmpty) ...[
                          _buildDetailItem(
                            icon: Icons.access_time_rounded,
                            title: 'Available Hours',
                            value: widget.counsellor.availableHours.join(', '),
                          ),
                          const Divider(height: 32),
                        ],
                        _buildDetailItem(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          value: widget.counsellor.email,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Request Support Section
                  if (_isCheckingStatus)
                    const Center(child: CircularProgressIndicator())
                  else if (_hasPendingRequest)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.secondaryContainer,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.secondary,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'You already have a pending support request. Please wait for a response.',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Tell us how we can help...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : _submitSupportRequest,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit Request'),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
