import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/measurement.dart';
import '../../models/measurement_guide.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../measurements/measurement_input_screen.dart';

class MeasurementDetailScreen extends StatelessWidget {
  final MeasurementGuide guide;

  const MeasurementDetailScreen({
    super.key,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final history = provider.getMeasurementsByType(guide.type);
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
                  _buildSummaryCard(context, history),
                  const SizedBox(height: 24),
                  const Text('Progress Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildChart(chartData),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MeasurementInputScreen(guide: guide)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryTable(context, provider, history),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Measurement> history) {
    final latestValue = history.isNotEmpty ? history.first.value : null;
    final previousValue = history.length > 1 ? history[1].value : null;
    final diff = (latestValue != null && previousValue != null) ? latestValue - previousValue : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(guide.icon, color: guide.color, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(latestValue?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(guide.unit, style: const TextStyle(color: AppTheme.textSecondary)),
            ]),
          ),
          if (diff != null) _buildDiffBadge(diff),
        ],
      ),
    );
  }

  Widget _buildDiffBadge(double diff) {
    final isNegative = diff < 0;
    final color = diff == 0 ? Colors.grey : (isNegative ? Colors.green : Colors.red);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text('${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const Text('Since last', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildChart(List<Measurement> chartData) {
    if (chartData.length < 2) return const SizedBox(height: 200, child: Center(child: Text('Not enough data')));
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
            isCurved: true,
            color: guide.color,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: guide.color.withOpacity(0.1)),
          ),
        ],
      )),
    );
  }

  Widget _buildHistoryTable(BuildContext context, AppProvider provider, List<Measurement> history) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
      itemBuilder: (context, index) {
        final item = history[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
          onDismissed: (_) => provider.deleteMeasurement(item.id!),
          child: ListTile(
            title: Text('${item.value} ${guide.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMM d, y').format(item.measuredAt)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, size: 20),
              onPressed: () => _editEntry(context, provider, item),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editEntry(BuildContext context, AppProvider provider, Measurement item) async {
    final controller = TextEditingController(text: item.value.toString());
    DateTime selectedDate = item.measuredAt;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(suffixText: guide.unit),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(DateFormat('MMM d, y').format(selectedDate)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  Navigator.pop(context, {'value': value, 'date': selectedDate});
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      provider.updateMeasurement(item.copyWith(
        value: result['value'] as double,
        measuredAt: result['date'] as DateTime,
      ));
    }
  }
}
