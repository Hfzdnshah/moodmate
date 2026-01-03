import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/mood_entry_model.dart';
import '../../models/support_request_model.dart';
import '../../services/mood_entry_service.dart';
import 'package:fl_chart/fl_chart.dart';

class UserMoodSummaryScreen extends StatefulWidget {
  final UserModel user;

  const UserMoodSummaryScreen({super.key, required this.user});

  @override
  State<UserMoodSummaryScreen> createState() => _UserMoodSummaryScreenState();
}

class _UserMoodSummaryScreenState extends State<UserMoodSummaryScreen> {
  final MoodEntryService _moodEntryService = MoodEntryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  bool _hasAccess = false;
  String? _errorMessage;
  String _selectedFilter = 'week';

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  Future<void> _checkAccessAndLoadData() async {
    final counsellor = FirebaseAuth.instance.currentUser;
    if (counsellor == null) {
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
      // Check if counsellor has access to this user via support requests
      final supportRequestSnapshot = await _firestore
          .collection('support_requests')
          .where('userId', isEqualTo: widget.user.id)
          .where('counsellorId', isEqualTo: counsellor.uid)
          .where(
            'status',
            whereIn: [
              SupportRequestStatus.accepted.name,
              SupportRequestStatus.inProgress.name,
            ],
          )
          .limit(1)
          .get();

      final hasAccess = supportRequestSnapshot.docs.isNotEmpty;

      if (!hasAccess) {
        setState(() {
          _hasAccess = false;
          _errorMessage = 'Access denied. User is not assigned to you.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _hasAccess = true;
      });

      await _loadMoodEntries();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoodEntries() async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedFilter) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'all':
          startDate = DateTime(2020);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      final entries = await _moodEntryService.getUserMoodEntriesByDateRange(
        widget.user.id,
        startDate,
        now,
      );

      setState(() {
        _moodEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.user.name}\'s Mood Summary')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAccess || _errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'You do not have access to this user\'s data.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          _buildUserInfoCard(),
          const SizedBox(height: 24),

          // Filter Options
          _buildFilterOptions(),
          const SizedBox(height: 24),

          // Mood Statistics
          _buildMoodStatistics(),
          const SizedBox(height: 24),

          // Mood Trend Chart
          _buildMoodTrendChart(),
          const SizedBox(height: 24),

          // Recent Mood Entries
          _buildRecentEntries(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : 'U',
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
                    widget.user.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Range',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
                ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                  _isLoading = true;
                });
                _loadMoodEntries();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodStatistics() {
    if (_moodEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No mood entries for this period',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    // Calculate statistics
    final completedEntries = _moodEntries
        .where((e) => e.emotion != null)
        .toList();
    final emotionCounts = <String, int>{};

    for (final entry in completedEntries) {
      final emotion = entry.emotion!;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    final mostCommonEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Entries', _moodEntries.length.toString()),
            const SizedBox(height: 8),
            _buildStatRow(
              'Analyzed Entries',
              completedEntries.length.toString(),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Most Common Mood',
              _capitalize(mostCommonEmotion),
              color: _getEmotionColor(mostCommonEmotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTrendChart() {
    if (_moodEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedEntries = _moodEntries
        .where((e) => e.emotion != null)
        .toList();

    if (completedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group entries by emotion
    final emotionCounts = <String, int>{};
    for (final entry in completedEntries) {
      final emotion = entry.emotion!;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: emotionCounts.entries.map((entry) {
                    final percentage =
                        (entry.value / completedEntries.length) * 100;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: _getEmotionColor(entry.key),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: emotionCounts.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getEmotionColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_capitalize(entry.key)} (${entry.value})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    if (_moodEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Entries',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...(_moodEntries.take(10).map((entry) => _buildEntryCard(entry))),
      ],
    );
  }

  Widget _buildEntryCard(MoodEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (entry.emotion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getEmotionColor(entry.emotion!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getEmotionColor(entry.emotion!),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _capitalize(entry.emotion!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getEmotionColor(entry.emotion!),
                      ),
                    ),
                  ),
                Text(
                  _formatDateTime(entry.timestamp),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happiness':
      case 'excited':
      case 'excitement':
        return Colors.yellow[700]!;
      case 'sadness':
      case 'sad':
        return Colors.blue[700]!;
      case 'anxiety':
      case 'anxious':
      case 'stressed':
        return Colors.orange[700]!;
      case 'anger':
      case 'angry':
      case 'frustrated':
      case 'frustration':
        return Colors.red[700]!;
      case 'fear':
      case 'scared':
        return Colors.purple[700]!;
      case 'contentment':
      case 'content':
      case 'peaceful':
        return Colors.green[700]!;
      case 'loneliness':
      case 'lonely':
        return Colors.blueGrey[700]!;
      case 'hope':
      case 'hopeful':
        return Colors.lightBlue[700]!;
      case 'overwhelmed':
        return Colors.deepOrange[700]!;
      case 'confused':
        return Colors.amber[700]!;
      case 'grateful':
        return Colors.pink[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
