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

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(category);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('At least one category must be selected')),
          );
        }
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: ReorderableListView(
        padding: const EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _selectedCategories.removeAt(oldIndex);
            _selectedCategories.insert(newIndex, item);
          });
        },
        children: [
          ..._selectedCategories.map((cat) => _buildItem(cat, true)).toList(),
          const Divider(key: ValueKey('divider'), height: 32),
          ..._getAvailableCategories()
              .where((cat) => !_selectedCategories.contains(cat))
              .map((cat) => _buildItem(cat, false))
              .toList(),
        ],
      ),
    );
  }

  List<String> _getAvailableCategories() {
    return [
      'bmi',
      'whr',
      ...MeasurementGuide.guides.map((g) => g.type),
    ];
  }

  Widget _buildItem(String category, bool isSelected) {
    final title = _getCategoryTitle(category);
    final icon = _getCategoryIcon(category);
    final color = _getCategoryColor(category);

    return ListTile(
      key: ValueKey(category),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: isSelected 
          ? const Icon(Icons.reorder, color: AppTheme.textSecondary)
          : const Icon(Icons.add, color: AppTheme.primaryColor),
      onTap: () => _toggleCategory(category),
    );
  }

  String _getCategoryTitle(String category) {
    if (category == 'bmi') return 'BMI';
    if (category == 'whr') return 'Waist/Hip Ratio';
    return MeasurementGuide.guides.firstWhere((g) => g.type == category).title;
  }

  IconData _getCategoryIcon(String category) {
    if (category == 'bmi') return Icons.monitor_weight_outlined;
    if (category == 'whr') return Icons.accessibility_new;
    return MeasurementGuide.guides.firstWhere((g) => g.type == category).icon;
  }

  Color _getCategoryColor(String category) {
    if (category == 'bmi') return AppTheme.primaryColor;
    if (category == 'whr') return AppTheme.secondaryColor;
    return MeasurementGuide.guides.firstWhere((g) => g.type == category).color;
  }
}
