import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../models/measurement_guide.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal? goal;
  const GoalDetailScreen({super.key, this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late String _selectedType;
  late TextEditingController _targetValueController;
  late DateTime _targetDate;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _isEdit = true;
      _selectedType = widget.goal!.type;
      _targetValueController = TextEditingController(text: widget.goal!.targetValue.toString());
      _targetDate = widget.goal!.targetDate;
    } else {
      _selectedType = 'weight';
      _targetValueController = TextEditingController();
      _targetDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final provider = context.read<AppProvider>();
    final userId = provider.currentUser?.id;
    if (userId == null) return;

    final targetValue = double.tryParse(_targetValueController.text);
    if (targetValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid target value')));
      return;
    }

    final startValue = provider.getLatestMeasurement(_selectedType)?.value ?? targetValue;

    if (_isEdit) {
      final updatedGoal = widget.goal!.copyWith(
        type: _selectedType,
        targetValue: targetValue,
        targetDate: _targetDate,
      );
      await provider.updateGoal(updatedGoal);
    } else {
      final newGoal = Goal(
        userId: userId,
        type: _selectedType,
        startValue: startValue,
        targetValue: targetValue,
        startDate: DateTime.now(),
        targetDate: _targetDate,
      );
      await provider.addGoal(newGoal);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Goal' : 'New Goal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Goal Category', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 32),
            const Text('Target Value', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: _targetValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                suffixText: MeasurementGuide.guides.firstWhere((g) => g.type == _selectedType).unit,
              ),
            ),
            const SizedBox(height: 32),
            const Text('Target Date', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _saveGoal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () async {
                    await context.read<AppProvider>().deleteGoal(widget.goal!.id!);
                    if (mounted) Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Center(child: Text('Delete Goal')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: AppTheme.cardColor,
          items: MeasurementGuide.guides.map((g) {
            return DropdownMenuItem(
              value: g.type,
              child: Row(
                children: [
                  Icon(g.icon, color: g.color, size: 20),
                  const SizedBox(width: 12),
                  Text(g.title),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _targetDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) setState(() => _targetDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 16),
            Text(DateFormat('MMMM d, y').format(_targetDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
