import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/mood_entry_model.dart';
import 'mood_entry_detail_screen.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Date range filter options
  DateTimeRange? _selectedDateRange;
  String _filterOption = 'all'; // all, week, month, custom

  // Pagination
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Search
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filterOption != 'all') _buildFilterChip(),
          Expanded(
            child: _buildMoodList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    String filterText = '';
    switch (_filterOption) {
      case 'week':
        filterText = 'Last 7 days';
        break;
      case 'month':
        filterText = 'Last 30 days';
        break;
      case 'custom':
        if (_selectedDateRange != null) {
          final start = DateFormat.yMMMd().format(_selectedDateRange!.start);
          final end = DateFormat.yMMMd().format(_selectedDateRange!.end);
          filterText = '$start - $end';
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Chip(
        label: Text(filterText),
        deleteIcon: const Icon(Icons.close),
        onDeleted: () {
          setState(() {
            _filterOption = 'all';
            _selectedDateRange = null;
            _lastDocument = null;
            _hasMore = true;
          });
        },
      ),
    );
  }

  Widget _buildMoodList() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your mood history'));
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('mood_entries')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true);

    // Apply date range filter
    if (_filterOption == 'week') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo));
    } else if (_filterOption == 'month') {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo));
    } else if (_filterOption == 'custom' && _selectedDateRange != null) {
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.end.add(const Duration(days: 1))));
    }

    query = query.limit(_pageSize);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Filter by search query if present
        final filteredDocs = _searchQuery.isEmpty
            ? docs
            : docs.where((doc) {
                final data = doc.data();
                final text = data['text']?.toString().toLowerCase() ?? '';
                final emotion = data['emotion']?.toString().toLowerCase() ?? '';
                return text.contains(_searchQuery.toLowerCase()) ||
                    emotion.contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mood_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No mood entries yet' : 'No entries found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Start tracking your mood today!'
                      : 'Try a different search term',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!_isLoadingMore &&
                _hasMore &&
                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              _loadMoreEntries();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == filteredDocs.length) {
                return _isLoadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final doc = filteredDocs[index];
              final moodEntry = MoodEntry.fromFirestore(doc);

              return _buildMoodCard(moodEntry);
            },
          ),
        );
      },
    );
  }

  Widget _buildMoodCard(MoodEntry entry) {
    final timestamp = entry.timestamp;
    final dateStr = DateFormat('MMM d, yyyy').format(timestamp);
    final timeStr = DateFormat('h:mm a').format(timestamp);

    final emotion = entry.emotion ?? 'analyzing...';
    final emotionColor = _getEmotionColor(emotion);
    final emotionIcon = _getEmotionIcon(emotion);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MoodEntryDetailScreen(entryId: entry.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(emotionIcon, color: emotionColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emotion.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: emotionColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr at $timeStr',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (entry.confidenceScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(entry.confidenceScore! * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (entry.recommendations != null && entry.recommendations!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.recommendations!.length} recommendations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'excitement':
      case 'grateful':
        return Colors.amber;
      case 'sadness':
      case 'loneliness':
        return Colors.blue;
      case 'anxiety':
      case 'fear':
      case 'stressed':
      case 'overwhelmed':
        return Colors.orange;
      case 'anger':
      case 'frustration':
        return Colors.red;
      case 'contentment':
      case 'peaceful':
        return Colors.green;
      case 'hope':
        return Colors.teal;
      case 'confused':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'excitement':
        return Icons.sentiment_very_satisfied;
      case 'sadness':
      case 'loneliness':
        return Icons.sentiment_dissatisfied;
      case 'anxiety':
      case 'fear':
      case 'stressed':
      case 'overwhelmed':
        return Icons.sentiment_very_dissatisfied;
      case 'anger':
      case 'frustration':
        return Icons.mood_bad;
      case 'contentment':
      case 'peaceful':
        return Icons.sentiment_satisfied;
      case 'hope':
        return Icons.wb_sunny;
      case 'grateful':
        return Icons.favorite;
      case 'confused':
        return Icons.help_outline;
      default:
        return Icons.mood;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchQuery;
        return AlertDialog(
          title: const Text('Search Entries'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by text or emotion...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => searchText = value,
            onSubmitted: (value) {
              setState(() => _searchQuery = value.trim());
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = searchText.trim());
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Time'),
                leading: Radio<String>(
                  value: 'all',
                  groupValue: _filterOption,
                  onChanged: (value) {
                    setState(() {
                      _filterOption = value!;
                      _selectedDateRange = null;
                      _lastDocument = null;
                      _hasMore = true;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Last 7 Days'),
                leading: Radio<String>(
                  value: 'week',
                  groupValue: _filterOption,
                  onChanged: (value) {
                    setState(() {
                      _filterOption = value!;
                      _selectedDateRange = null;
                      _lastDocument = null;
                      _hasMore = true;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Last 30 Days'),
                leading: Radio<String>(
                  value: 'month',
                  groupValue: _filterOption,
                  onChanged: (value) {
                    setState(() {
                      _filterOption = value!;
                      _selectedDateRange = null;
                      _lastDocument = null;
                      _hasMore = true;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Custom Range'),
                leading: Radio<String>(
                  value: 'custom',
                  groupValue: _filterOption,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _selectCustomDateRange();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _filterOption = 'custom';
        _selectedDateRange = picked;
        _lastDocument = null;
        _hasMore = true;
      });
    }
  }

  Future<void> _loadMoreEntries() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true);

      // Apply date range filter
      if (_filterOption == 'week') {
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo));
      } else if (_filterOption == 'month') {
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo));
      } else if (_filterOption == 'custom' && _selectedDateRange != null) {
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.start))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.end.add(const Duration(days: 1))));
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.limit(_pageSize).get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more entries: $e')),
        );
      }
    }
  }
}
