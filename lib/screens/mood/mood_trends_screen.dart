import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/mood_entry_model.dart';

class MoodTrendsScreen extends StatefulWidget {
  const MoodTrendsScreen({super.key});

  @override
  State<MoodTrendsScreen> createState() => _MoodTrendsScreenState();
}

class _MoodTrendsScreenState extends State<MoodTrendsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _chartType = 'line'; // line, bar, calendar
  int _daysToShow = 7; // 7, 14, 30

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Trends'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.show_chart),
            onSelected: (value) => setState(() => _chartType = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'line', child: Text('Line Chart')),
              const PopupMenuItem(value: 'bar', child: Text('Bar Chart')),
              const PopupMenuItem(value: 'calendar', child: Text('Calendar View')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeRangeSelector(),
          Expanded(
            child: _buildChart(),
          ),
          _buildEmotionLegend(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeRangeChip('7 Days', 7),
          _buildTimeRangeChip('14 Days', 14),
          _buildTimeRangeChip('30 Days', 30),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, int days) {
    final isSelected = _daysToShow == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _daysToShow = days);
        }
      },
    );
  }

  Widget _buildChart() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view trends'));
    }

    final startDate = DateTime.now().subtract(Duration(days: _daysToShow));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_chart_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No data for the selected period',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your mood to see trends',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final entries = docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();

        switch (_chartType) {
          case 'bar':
            return _buildBarChart(entries);
          case 'calendar':
            return _buildCalendarView(entries);
          case 'line':
          default:
            return _buildLineChart(entries);
        }
      },
    );
  }

  Widget _buildLineChart(List<MoodEntry> entries) {
    // Map emotions to numeric values for visualization
    final emotionValues = <String, double>{
      'joy': 5,
      'excitement': 5,
      'grateful': 4.5,
      'hope': 4,
      'contentment': 3.5,
      'peaceful': 3.5,
      'confused': 3,
      'anxiety': 2.5,
      'stressed': 2.5,
      'overwhelmed': 2,
      'frustration': 2,
      'sadness': 1.5,
      'loneliness': 1.5,
      'anger': 1,
      'fear': 1,
    };

    final spots = <FlSpot>[];
    final startDate = DateTime.now().subtract(Duration(days: _daysToShow));

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.emotion != null) {
        final value = emotionValues[entry.emotion!.toLowerCase()] ?? 3;
        final timestamp = entry.timestamp;
        final daysDiff = timestamp.difference(startDate).inDays.toDouble();
        spots.add(FlSpot(daysDiff, value));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No emotion data available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  const emotions = ['Fear', 'Sad', 'Anxious', 'Neutral', 'Content', 'Joy'];
                  final index = value.toInt() - 1;
                  if (index >= 0 && index < emotions.length) {
                    return Text(
                      emotions[index],
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final date = startDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minY: 0,
          maxY: 6,
          minX: 0,
          maxX: _daysToShow.toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MoodEntry> entries) {
    // Count occurrences of each emotion
    final emotionCounts = <String, int>{};
    for (final entry in entries) {
      if (entry.emotion != null) {
        final emotion = entry.emotion!.toLowerCase();
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    if (emotionCounts.isEmpty) {
      return const Center(child: Text('No emotion data available'));
    }

    // Sort by count descending
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 10
    final topEmotions = sortedEmotions.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topEmotions.first.value.toDouble() + 1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final emotion = topEmotions[group.x.toInt()].key;
                final count = topEmotions[group.x.toInt()].value;
                return BarTooltipItem(
                  '$emotion\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '$count ${count == 1 ? 'entry' : 'entries'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topEmotions.length) {
                    final emotion = topEmotions[index].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        emotion.substring(0, emotion.length > 5 ? 5 : emotion.length),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(topEmotions.length, (index) {
            final emotion = topEmotions[index].key;
            final count = topEmotions[index].value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: _getEmotionColor(emotion),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCalendarView(List<MoodEntry> entries) {
    // Group entries by date
    final entriesByDate = <DateTime, List<MoodEntry>>{};
    for (final entry in entries) {
      final date = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      entriesByDate.putIfAbsent(date, () => []).add(entry);
    }

    final startDate = DateTime.now().subtract(Duration(days: _daysToShow));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _daysToShow,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final dateKey = DateTime(date.year, date.month, date.day);
          final dayEntries = entriesByDate[dateKey] ?? [];

          Color color = Colors.grey.shade200;
          String emoji = '';

          if (dayEntries.isNotEmpty) {
            // Use the most common emotion for that day
            final emotionCounts = <String, int>{};
            for (final entry in dayEntries) {
              if (entry.emotion != null) {
                final emotion = entry.emotion!.toLowerCase();
                emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
              }
            }

            if (emotionCounts.isNotEmpty) {
              final mostCommonEmotion = emotionCounts.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key;
              color = _getEmotionColor(mostCommonEmotion).withOpacity(0.6);
              emoji = _getEmotionEmoji(mostCommonEmotion);
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(date),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                if (emoji.isNotEmpty)
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmotionLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotion Legend',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildLegendItem('Joy/Excitement', Colors.amber),
              _buildLegendItem('Content/Peaceful', Colors.green),
              _buildLegendItem('Hope', Colors.teal),
              _buildLegendItem('Anxious/Stressed', Colors.orange),
              _buildLegendItem('Sad/Lonely', Colors.blue),
              _buildLegendItem('Angry', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
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

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'excitement':
        return '😄';
      case 'sadness':
      case 'loneliness':
        return '😢';
      case 'anxiety':
      case 'fear':
        return '😰';
      case 'anger':
      case 'frustration':
        return '😠';
      case 'contentment':
      case 'peaceful':
        return '😌';
      case 'stressed':
      case 'overwhelmed':
        return '😓';
      case 'hope':
        return '🌟';
      case 'grateful':
        return '🙏';
      case 'confused':
        return '😕';
      default:
        return '😐';
    }
  }
}
