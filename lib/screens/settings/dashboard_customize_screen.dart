import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/measurement_guide.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class DashboardCustomizeScreen extends StatefulWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  State<DashboardCustomizeScreen> createState() => _DashboardCustomizeScreenState();
}

class _DashboardCustomizeScreenState extends State<DashboardCustomizeScreen> {
  late List<String> _selectedCategories;
  
  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _selectedCategories = List.from(provider.dashboardCategories);
  }

  void _save() {
    context.read<AppProvider>().setDashboardCategories(_selectedCategories);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get latest guides
    final provider = context.watch<AppProvider>();
    final guides = provider.allGuides;
    
    // Calculate unselected
    final available = [
      'bmi',
      'whr',
      ...guides.map((g) => g.type),
    ];
    final unselected = available.where((c) => !_selectedCategories.contains(c)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AppProvider>().setDashboardCategories(_selectedCategories);
              Navigator.pop(context);
            },
            child: const Text('SAVE', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Drag to reorder. Tap "X" to remove.', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _selectedCategories.removeAt(oldIndex);
                  _selectedCategories.insert(newIndex, item);
                });
              },
              children: [
                for (final cat in _selectedCategories)
                  _buildSelectedItem(cat, guides),
              ],
            ),
          ),
          if (unselected.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Available to Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final cat in unselected)
                    _buildUnselectedItem(cat, guides),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedItem(String category, List<MeasurementGuide> guides) {
    final title = _getCategoryTitle(category, guides);
    final icon = _getCategoryIcon(category, guides);
    final color = _getCategoryColor(category, guides);

    return Container(
      key: ValueKey(category),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            setState(() {
              _selectedCategories.remove(category);
            });
          },
        ),
      ),
    );
  }

  Widget _buildUnselectedItem(String category, List<MeasurementGuide> guides) {
    final title = _getCategoryTitle(category, guides);
    final icon = _getCategoryIcon(category, guides);
    final color = _getCategoryColor(category, guides);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color.withOpacity(0.7)),
        title: Text(title, style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.7))),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
          onPressed: () {
            setState(() {
              _selectedCategories.add(category);
            });
          },
        ),
      ),
    );
  }

  String _getCategoryTitle(String category, List<MeasurementGuide> guides) {
    if (category == 'bmi') return 'BMI';
    if (category == 'whr') return 'Waist/Hip Ratio';
    try {
      return guides.firstWhere((g) => g.type == category).title;
    } catch (_) {
      return category;
    }
  }

  IconData _getCategoryIcon(String category, List<MeasurementGuide> guides) {
    if (category == 'bmi') return Icons.monitor_weight_outlined;
    if (category == 'whr') return Icons.accessibility_new;
    try {
      return guides.firstWhere((g) => g.type == category).icon;
    } catch (_) {
      return Icons.help_outline;
    }
  }

  Color _getCategoryColor(String category, List<MeasurementGuide> guides) {
    if (category == 'bmi') return AppTheme.primaryColor;
    if (category == 'whr') return AppTheme.secondaryColor;
    try {
      return guides.firstWhere((g) => g.type == category).color;
    } catch (_) {
      return Colors.grey;
    }
  }
}
