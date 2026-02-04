import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/goal.dart';
import '../../models/measurement_guide.dart';
import '../../utils/app_theme.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final goals = provider.goals;
          
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text('No goals set yet', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalDetailScreen())),
                    child: const Text('Add Your First Goal'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final guide = MeasurementGuide.guides.firstWhere((g) => g.type == goal.type);
              final latest = provider.getLatestMeasurement(goal.type)?.value ?? goal.startValue;
              
              double progress = 0;
              final totalDiff = (goal.targetValue - goal.startValue).abs();
              final currentDiff = (latest - goal.startValue).abs();
              if (totalDiff > 0) {
                progress = (currentDiff / totalDiff).clamp(0.0, 1.0);
              }

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: guide.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(guide.icon, color: guide.color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(guide.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  'Target: ${goal.targetValue} ${guide.unit} by ${DateFormat('MMM d, y').format(goal.targetDate)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text('${(progress * 100).toInt()}%', style: TextStyle(color: guide.color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(guide.color),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${goal.startValue} ${guide.unit}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          Text('Current: $latest ${guide.unit}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('${goal.targetValue} ${guide.unit}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalDetailScreen())),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
