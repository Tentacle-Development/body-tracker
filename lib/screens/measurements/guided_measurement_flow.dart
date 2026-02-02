import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/measurement_guide.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'measurement_input_screen.dart';

class GuidedMeasurementFlow extends StatefulWidget {
  const GuidedMeasurementFlow({super.key});

  @override
  State<GuidedMeasurementFlow> createState() => _GuidedMeasurementFlowState();
}

class _GuidedMeasurementFlowState extends State<GuidedMeasurementFlow> {
  final Set<String> _completedMeasurements = {};

  @override
  Widget build(BuildContext context) {
    final guides = MeasurementGuide.guides;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Measure Your Body'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_completedMeasurements.length} of ${guides.length} completed',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${((_completedMeasurements.length / guides.length) * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _completedMeasurements.length / guides.length,
                    backgroundColor: AppTheme.cardColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Measurement list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: guides.length,
              itemBuilder: (context, index) {
                final guide = guides[index];
                final isCompleted = _completedMeasurements.contains(guide.type);
                final provider = Provider.of<AppProvider>(context);
                final latestMeasurement = provider.getLatestMeasurement(guide.type);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MeasurementTile(
                    guide: guide,
                    isCompleted: isCompleted,
                    latestValue: latestMeasurement?.value,
                    onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => MeasurementInputScreen(guide: guide),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          _completedMeasurements.add(guide.type);
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Done button
          if (_completedMeasurements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  final MeasurementGuide guide;
  final bool isCompleted;
  final double? latestValue;
  final VoidCallback onTap;

  const _MeasurementTile({
    required this.guide,
    required this.isCompleted,
    this.latestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isCompleted
                ? Border.all(color: AppTheme.success.withValues(alpha: 0.5), width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: guide.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  guide.icon,
                  color: guide.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Title & description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestValue != null
                          ? '${latestValue!.toStringAsFixed(1)} ${guide.unit}'
                          : guide.description,
                      style: TextStyle(
                        color: latestValue != null
                            ? guide.color
                            : AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Status icon
              if (isCompleted)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.success,
                    size: 20,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
