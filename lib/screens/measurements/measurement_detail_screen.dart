import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/measurement.dart';
import '../../models/measurement_guide.dart';
import '../../utils/app_theme.dart';

class MeasurementDetailScreen extends StatelessWidget {
  final MeasurementGuide guide;
  final List<Measurement> history;

  const MeasurementDetailScreen({
    super.key,
    required this.guide,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    // Sort history by date ascending for the chart
    final chartData = List<Measurement>.from(history)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return Scaffold(
      appBar: AppBar(
        title: Text('${guide.title} Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              _buildSummaryCard(context),
              const SizedBox(height: 24),
              
              // Chart Section
              const Text(
                'Progress Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildChart(chartData),
              const SizedBox(height: 32),
              
              // History Table
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildHistoryTable(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final latestValue = history.isNotEmpty ? history.first.value : null;
    final previousValue = history.length > 1 ? history[1].value : null;
    final diff = (latestValue != null && previousValue != null) 
        ? latestValue - previousValue 
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: guide.color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: guide.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(guide.icon, color: guide.color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latestValue?.toStringAsFixed(1) ?? '--',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  guide.unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (diff != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (diff == 0) 
                        ? Colors.grey.withValues(alpha: 0.2)
                        : (diff < 0 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        diff == 0 ? Icons.remove : (diff < 0 ? Icons.arrow_downward : Icons.arrow_upward),
                        size: 14,
                        color: diff == 0 ? Colors.grey : (diff < 0 ? Colors.green : Colors.red),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${diff.abs().toStringAsFixed(1)}',
                        style: TextStyle(
                          color: diff == 0 ? Colors.grey : (diff < 0 ? Colors.green : Colors.red),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Since last',
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Measurement> chartData) {
    if (chartData.length < 2) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Add more data to see progress chart',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                    final date = chartData[value.toInt()].measuredAt;
                    // Only show first, middle, and last date
                    if (value.toInt() == 0 || 
                        value.toInt() == chartData.length - 1 || 
                        value.toInt() == chartData.length ~/ 2) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      );
                    }
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.value);
              }).toList(),
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
    );
  }

  Widget _buildHistoryTable(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No history entries yet'));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              '${item.value} ${guide.unit}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              DateFormat('EEEE, MMMM d, y').format(item.measuredAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
          );
        },
      ),
    );
  }
}
