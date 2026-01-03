import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Debug: Print counsellor ID
      print('DEBUG: Loading clients for counsellor: ${user.uid}');

      // First, check ALL support requests for this counsellor (any status)
      final allRequestsSnapshot = await _firestore
          .collection('support_requests')
          .where('counsellorId', isEqualTo: user.uid)
          .get();

      print(
        'DEBUG: Total support requests for this counsellor (any status): ${allRequestsSnapshot.docs.length}',
      );
      for (var doc in allRequestsSnapshot.docs) {
        print(
          'DEBUG: Request ${doc.id}: status=${doc.data()['status']}, userId=${doc.data()['userId']}',
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
      print(
        'DEBUG: Found ${requestsSnapshot.docs.length} accepted/inProgress requests',
      );
      for (var doc in requestsSnapshot.docs) {
        print(
          'DEBUG: Request ${doc.id}: userId=${doc.data()['userId']}, status=${doc.data()['status']}',
        );
      }

      // Get unique user IDs
      final Set<String> userIds = requestsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet();

      print('DEBUG: Unique user IDs: $userIds');

      if (userIds.isEmpty) {
        print('DEBUG: No users found, showing empty state');
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

      print('DEBUG: Loaded ${users.length} user details');

      setState(() {
        _assignedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading assigned users: $e');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedUsers,
          ),
        ],
      ),
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
              'Failed to load clients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
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
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
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
        padding: const EdgeInsets.all(16),
        itemCount: _assignedUsers.length,
        itemBuilder: (context, index) {
          final user = _assignedUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserMoodSummaryScreen(user: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatDate(user.createdAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
