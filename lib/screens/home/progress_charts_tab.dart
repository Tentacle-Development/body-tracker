import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/measurement.dart';
import '../../models/measurement_guide.dart';
import '../../models/goal.dart';
import '../measurements/measurement_input_screen.dart';
import '../../utils/app_theme.dart';

class ProgressChartsTab extends StatefulWidget {
  const ProgressChartsTab({super.key});

  @override
  State<ProgressChartsTab> createState() => _ProgressChartsTabState();
}

class _ProgressChartsTabState extends State<ProgressChartsTab> {
  String _selectedType = 'weight';
  String _selectedRange = 'All';

  final List<String> _ranges = ['1M', '3M', '6M', '1Y', 'All'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Charts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Type Selector
            _buildTypeSelector(),
            const SizedBox(height: 16),
            
            // Range Selector
            _buildRangeSelector(),
            const SizedBox(height: 24),
            
            // Main Chart & Stats
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final allHistory = provider.getMeasurementsByType(_selectedType);
                  final filteredHistory = _filterHistoryByRange(allHistory, _selectedRange);
                  final guide = MeasurementGuide.guides.firstWhere((g) => g.type == _selectedType);
                  
                  if (filteredHistory.isEmpty) {
                    return _buildEmptyState(guide);
                  }

                  // Find active goal
                  final goals = provider.goals.where((g) => g.type == _selectedType && !g.isCompleted).toList();
                  final activeGoal = goals.isNotEmpty ? goals.first : null;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMainChart(filteredHistory, guide, activeGoal),
                        const SizedBox(height: 24),
                        _buildStatsSummary(filteredHistory, guide, activeGoal),
                        const SizedBox(height: 20),
                        _buildHistoryList(filteredHistory, guide),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MeasurementGuide.guides.map((guide) {
          final isSelected = _selectedType == guide.type;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(guide.title),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = guide.type);
              },
              selectedColor: guide.color.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? guide.color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _ranges.map((range) {
        final isSelected = _selectedRange == range;
        return GestureDetector(
          onTap: () => setState(() => _selectedRange = range),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Measurement> _filterHistoryByRange(List<Measurement> history, String range) {
    if (range == 'All') return history;
    
    final now = DateTime.now();
    DateTime cutoff;
    
    switch (range) {
      case '1M': cutoff = now.subtract(const Duration(days: 30)); break;
      case '3M': cutoff = now.subtract(const Duration(days: 90)); break;
      case '6M': cutoff = now.subtract(const Duration(days: 180)); break;
      case '1Y': cutoff = now.subtract(const Duration(days: 365)); break;
      default: return history;
    }
    
    return history.where((m) => m.measuredAt.isAfter(cutoff)).toList();
  }

  Widget _buildEmptyState(MeasurementGuide guide) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'Not enough data for this range',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add at least 2 measurements to see a graph.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MeasurementInputScreen(guide: guide),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Measurement'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(List<Measurement> history, MeasurementGuide guide, Goal? goal) {
    // Sort ascending for chart
    final chartData = List<Measurement>.from(history)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final firstTimestamp = chartData.first.measuredAt.millisecondsSinceEpoch;
    final dayMillis = 1000 * 60 * 60 * 24;

    final spots = chartData.map((m) {
      final x = (m.measuredAt.millisecondsSinceEpoch - firstTimestamp).toDouble() / dayMillis;
      return FlSpot(x, m.value);
    }).toList();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardColor,
            AppTheme.surfaceColor.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundColor.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${guide.title} Progress',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${chartData.last.value} ${guide.unit}',
                    style: TextStyle(color: guide.color, fontWeight: FontWeight.bold),
                  ),
                  if (goal != null)
                    Text(
                      'Goal: ${goal.targetValue} ${guide.unit}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.last.x,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.cardColor.withValues(alpha: 0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          (barSpot.x * dayMillis).toInt() + firstTimestamp,
                        );
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n',
                          const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${barSpot.y} ${guide.unit}',
                              style: TextStyle(
                                color: guide.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.textPrimary.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getInterval(spots.last.x),
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          (value * dayMillis).toInt() + firstTimestamp,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (goal != null)
                      HorizontalLine(
                        y: goal.targetValue,
                        color: AppTheme.success.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold),
                          labelResolver: (line) => 'Goal',
                        ),
                      ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: LinearGradient(
                      colors: [
                        guide.color.withValues(alpha: 0.95),
                        guide.color.withValues(alpha: 0.55),
                      ],
                    ),
                    barWidth: 4.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == chartData.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 3.5,
                          color: guide.color,
                          strokeWidth: isLast ? 2.5 : 2,
                          strokeColor: AppTheme.cardColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          guide.color.withValues(alpha: 0.3),
                          guide.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(List<Measurement> history, MeasurementGuide guide, Goal? goal) {
    final values = history.map((m) => m.value).toList();
    final current = values.first; // Latest because sorted DESC in provider
    final first = values.last; // Oldest
    final diff = current - first;
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Progress percentage if goal exists
    double? progress;
    if (goal != null) {
      final totalToGoal = (goal.targetValue - goal.startValue).abs();
      final currentProgress = (current - goal.startValue).abs();
      if (totalToGoal > 0) {
        progress = (currentProgress / totalToGoal).clamp(0.0, 1.0);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Total Change', '${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)} ${guide.unit}', 
                diff == 0 ? AppTheme.textPrimary : (diff < 0 ? AppTheme.success : AppTheme.warning)),
              _buildStatItem('Average', '${avg.toStringAsFixed(1)} ${guide.unit}', AppTheme.textPrimary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Minimum', '${min.toStringAsFixed(1)} ${guide.unit}', AppTheme.textSecondary),
              _buildStatItem('Maximum', '${max.toStringAsFixed(1)} ${guide.unit}', AppTheme.textSecondary),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Goal Progress',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.textPrimary.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(guide.color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toInt()}% towards goal', style: TextStyle(color: guide.color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('${goal?.targetValue} ${guide.unit}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Measurement> history, MeasurementGuide guide) {
    final latestTen = history.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'History List',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text('Value', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
              Expanded(
                flex: 2,
                child: Text('Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
              Expanded(
                child: Text(
                  'Change',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: latestTen.length,
            separatorBuilder: (_, __) => Divider(
              color: AppTheme.textPrimary.withValues(alpha: 0.06),
              height: 16,
            ),
            itemBuilder: (context, index) {
              final current = latestTen[index];
              final previous = index + 1 < latestTen.length ? latestTen[index + 1] : null;
              final diff = previous != null ? current.value - previous.value : null;

              String diffText = '—';
              Color diffColor = AppTheme.textSecondary;
              if (diff != null) {
                final sign = diff > 0 ? '+' : '';
                diffText = '$sign${diff.toStringAsFixed(1)} ${guide.unit}';
                diffColor = diff == 0
                    ? AppTheme.textSecondary
                    : (diff < 0 ? AppTheme.success : AppTheme.warning);
              }

              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${current.value.toStringAsFixed(1)} ${guide.unit}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('MMM d, y').format(current.measuredAt),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      diffText,
                      textAlign: TextAlign.end,
                      style: TextStyle(color: diffColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  double _getInterval(double maxX) {
    if (maxX <= 7) return 1;
    if (maxX <= 31) return 7;
    if (maxX <= 90) return 30;
    if (maxX <= 365) return 60;
    return 90;
  }
}
