import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/measurement.dart';
import '../../models/measurement_guide.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class MeasurementInputScreen extends StatefulWidget {
  final MeasurementGuide guide;
  final VoidCallback? onComplete;

  const MeasurementInputScreen({
    super.key,
    required this.guide,
    this.onComplete,
  });

  @override
  State<MeasurementInputScreen> createState() => _MeasurementInputScreenState();
}

class _MeasurementInputScreenState extends State<MeasurementInputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _valueController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveMeasurement() async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value')),
      );
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    if (value < widget.guide.minValue || value > widget.guide.maxValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Value should be between ${widget.guide.minValue.toInt()} and ${widget.guide.maxValue.toInt()} ${widget.guide.unit}',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final measurement = Measurement(
        userId: provider.currentUser!.id!,
        type: widget.guide.type,
        value: value,
        unit: widget.guide.unit,
      );

      await provider.addMeasurement(measurement);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.guide.title} saved!'),
          backgroundColor: AppTheme.success,
        ),
      );

      widget.onComplete?.call();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: widget.guide.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      widget.guide.icon,
                      size: 50,
                      color: widget.guide.color,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.guide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.guide.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Instruction card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.guide.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: widget.guide.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to measure',
                            style: TextStyle(
                              color: widget.guide.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.guide.instruction,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Input field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.3),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          filled: true,
                          fillColor: AppTheme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: widget.guide.color, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: widget.guide.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.guide.unit,
                        style: TextStyle(
                          color: widget.guide.color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Range hint
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Expected range: ${widget.guide.minValue.toInt()} - ${widget.guide.maxValue.toInt()} ${widget.guide.unit}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),

                const Spacer(),

                // Save button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.guide.color,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Measurement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
