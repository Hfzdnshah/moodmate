import 'package:flutter/material.dart';
import '../../models/counsellor_model.dart';
import '../../services/counsellor_service.dart';
import 'counsellor_detail_screen.dart';

class CounsellorListScreen extends StatefulWidget {
  const CounsellorListScreen({super.key});

  @override
  State<CounsellorListScreen> createState() => _CounsellorListScreenState();
}

class _CounsellorListScreenState extends State<CounsellorListScreen> {
  final CounsellorService _counsellorService = CounsellorService();
  List<CounsellorModel> _counsellors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCounsellors();
  }

  Future<void> _loadCounsellors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final counsellors = await _counsellorService.getAvailableCounsellors();
      setState(() {
        _counsellors = counsellors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact a Counsellor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCounsellors,
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
              'Failed to load counsellors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCounsellors,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_counsellors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No counsellors available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Please check back later.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCounsellors,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCounsellors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _counsellors.length,
        itemBuilder: (context, index) {
          final counsellor = _counsellors[index];
          return _buildCounsellorCard(counsellor);
        },
      ),
    );
  }

  Widget _buildCounsellorCard(CounsellorModel counsellor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CounsellorDetailScreen(counsellor: counsellor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                backgroundImage: counsellor.profileImageUrl != null
                    ? NetworkImage(counsellor.profileImageUrl!)
                    : null,
                child: counsellor.profileImageUrl == null
                    ? Text(
                        counsellor.name.isNotEmpty
                            ? counsellor.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Counsellor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            counsellor.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              counsellor.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(counsellor.status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getStatusText(counsellor.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(counsellor.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (counsellor.specialization != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        counsellor.specialization!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (counsellor.yearsOfExperience != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${counsellor.yearsOfExperience} years of experience',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    if (counsellor.bio != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        counsellor.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
