import 'package:flutter/material.dart';
import '../models/habit_manager.dart';

class StatisticsWidget extends StatelessWidget {
  final int habitId;
  final HabitManager habitManager;

  const StatisticsWidget({
    super.key,
    required this.habitId,
    required this.habitManager,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: habitManager.getHabitStatistics(habitId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading statistics: ${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              final stats = snapshot.data!;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detailed Statistics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Streaks Section
                  _buildSectionTitle(context, '🔥 Streaks'),
                  _buildStatCard(
                    context: context,
                    title: 'Current Streak',
                    value: '${stats['currentStreak']} days',
                    subtitle: 'Keep it going!',
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    context: context,
                    title: 'Best Streak',
                    value: '${stats['maxStreak']} days',
                    subtitle: 'Your personal record',
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 24),

                  // Completion Stats Section
                  _buildSectionTitle(context, '📊 Completion Stats'),
                  _buildStatCard(
                    context: context,
                    title: 'Overall Completion Rate',
                    value: '${stats['completionRate'].toStringAsFixed(1)}%',
                    subtitle:
                        '${stats['completedCount']} out of ${stats['totalRecords']} days',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),

                  // Breakdown Section
                  _buildSectionTitle(context, '📈 Breakdown'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildBreakdownRow(
                            icon: '✅',
                            label: 'Completed',
                            count: stats['completedCount'],
                            color: Colors.green,
                          ),
                          const Divider(),
                          _buildBreakdownRow(
                            icon: '❌',
                            label: 'Missed',
                            count: stats['missedCount'],
                            color: Colors.red,
                          ),
                          const Divider(),
                          _buildBreakdownRow(
                            icon: '➖',
                            label: 'Skipped',
                            count: stats['skippedCount'],
                            color: Colors.amber,
                          ),
                          const Divider(),
                          _buildBreakdownRow(
                            icon: '📅',
                            label: 'Total Days Tracked',
                            count: stats['totalRecords'],
                            color: Colors.blue,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success Rate Visual
                  if (stats['totalRecords'] > 0) ...[
                    _buildSectionTitle(context, '🎯 Success Visualization'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completion Progress',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${stats['completionRate'].toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: stats['completionRate'] / 100,
                                minHeight: 20,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stats['completionRate'] >= 80
                                      ? Colors.green
                                      : stats['completionRate'] >= 50
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getMotivationalMessage(
                                  stats['completionRate'].toDouble()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String icon,
    required String label,
    required int count,
    required Color color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(double completionRate) {
    if (completionRate >= 90) {
      return '🌟 Outstanding! You\'re crushing it!';
    } else if (completionRate >= 80) {
      return '🎉 Excellent work! Keep it up!';
    } else if (completionRate >= 70) {
      return '💪 Great job! You\'re doing well!';
    } else if (completionRate >= 50) {
      return '👍 Good progress! Keep pushing!';
    } else if (completionRate >= 30) {
      return '📈 Making progress! Stay consistent!';
    } else {
      return '🚀 Every journey starts with a single step!';
    }
  }
}
