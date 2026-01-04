import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/user_model.dart';
import '../../models/support_request_model.dart';
import 'user_mood_summary_screen.dart';

class CounsellorDashboardScreen extends StatefulWidget {
  const CounsellorDashboardScreen({super.key});

  @override
  State<CounsellorDashboardScreen> createState() =>
      _CounsellorDashboardScreenState();
}

class _CounsellorDashboardScreenState extends State<CounsellorDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _assignedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignedUsers();
  }

  Future<void> _loadAssignedUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('Loading clients for counsellor: ${user.uid}');

      // First, check ALL support requests for this counsellor (any status)
      final allRequestsSnapshot = await _firestore
          .collection('support_requests')
          .where('counsellorId', isEqualTo: user.uid)
          .get();

      developer.log(
        'Total support requests for this counsellor (any status): ${allRequestsSnapshot.docs.length}',
      );
      for (var doc in allRequestsSnapshot.docs) {
        developer.log(
          'Request ${doc.id}: status=${doc.data()['status']}, userId=${doc.data()['userId']}',
        );
      }

      // Now get only accepted/inProgress ones
      final requestsSnapshot = await _firestore
          .collection('support_requests')
          .where('counsellorId', isEqualTo: user.uid)
          .where(
            'status',
            whereIn: [
              SupportRequestStatus.accepted.name,
              SupportRequestStatus.inProgress.name,
            ],
          )
          .get();

      // Debug: Print query results
      developer.log(
        'Found ${requestsSnapshot.docs.length} accepted/inProgress requests',
      );
      for (var doc in requestsSnapshot.docs) {
        developer.log(
          'Request ${doc.id}: userId=${doc.data()['userId']}, status=${doc.data()['status']}',
        );
      }

      // Get unique user IDs
      final Set<String> userIds = requestsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet();

      developer.log('Unique user IDs: $userIds');

      if (userIds.isEmpty) {
        developer.log('No users found, showing empty state');
        setState(() {
          _assignedUsers = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch user details
      final userDocs = await Future.wait(
        userIds.map(
          (userId) => _firestore.collection('users').doc(userId).get(),
        ),
      );

      final users = userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      developer.log('Loaded ${users.length} user details');

      setState(() {
        _assignedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading assigned users: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAssignedUsers,
          ),
        ],
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
              'Failed to load clients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadAssignedUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_assignedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No assigned clients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Clients will appear here when assigned to you.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _assignedUsers.length,
        itemBuilder: (context, index) {
          final user = _assignedUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserMoodSummaryScreen(user: user),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Member since ${_formatDate(user.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
