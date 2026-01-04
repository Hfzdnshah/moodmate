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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Counsellor'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCounsellors,
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
              'Failed to load counsellors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            FilledButton.tonal(
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
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No counsellors available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Please check back later.'),
            const SizedBox(height: 16),
            FilledButton.tonal(
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _counsellors.length,
        itemBuilder: (context, index) {
          final counsellor = _counsellors[index];
          return _buildCounsellorCard(counsellor);
        },
      ),
    );
  }

  Widget _buildCounsellorCard(CounsellorModel counsellor) {
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
                builder: (context) =>
                    CounsellorDetailScreen(counsellor: counsellor),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
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
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
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
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                counsellor.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(counsellor.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(counsellor.status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(counsellor.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (counsellor.specialization != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          counsellor.specialization!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                      if (counsellor.yearsOfExperience != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.work_outline_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${counsellor.yearsOfExperience} years exp.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (counsellor.bio != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          counsellor.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
