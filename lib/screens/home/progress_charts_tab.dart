import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/measurement.dart';
import '../../models/measurement_guide.dart';
import '../../models/goal.dart';
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
            
            // Main Chart
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final allHistory = provider.getMeasurementsByType(_selectedType);
                  final filteredHistory = _filterHistoryByRange(allHistory, _selectedRange);
                  final guide = MeasurementGuide.guides.firstWhere((g) => g.type == _selectedType);
                  
                  if (filteredHistory.length < 2) {
                    return _buildEmptyState();
                  }

                  return _buildMainChart(filteredHistory, guide);
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
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'Not enough data for this range',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add at least 2 measurements to see a graph.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(List<Measurement> history, MeasurementGuide guide) {
    // Sort ascending for chart
    final chartData = List<Measurement>.from(history)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    if (chartData.isEmpty) return _buildEmptyState();

    final provider = Provider.of<AppProvider>(context, listen: false);
    final goal = provider.goals.cast<Goal?>().firstWhere(
          (g) => g?.type == _selectedType && !g!.isCompleted,
          orElse: () => null,
        );

    final firstTimestamp = chartData.first.measuredAt.millisecondsSinceEpoch;
    final dayMillis = 1000 * 60 * 60 * 24;

    final spots = chartData.map((m) {
      final x = (m.measuredAt.millisecondsSinceEpoch - firstTimestamp).toDouble() / dayMillis;
      return FlSpot(x, m.value);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${guide.title} Progress',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.cardColor,
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
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
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
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          style: const TextStyle(fontSize: 9, color: Colors.redAccent),
                          labelResolver: (line) => 'Target',
                        ),
                      ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: guide.color,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: guide.color.withValues(alpha: 0.1),
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

  double _getInterval(double maxX) {
    if (maxX <= 7) return 1;
    if (maxX <= 31) return 7;
    if (maxX <= 90) return 30;
    if (maxX <= 365) return 60;
    return 90;
  }
}
