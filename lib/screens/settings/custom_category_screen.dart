import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/measurement_guide.dart';
import '../../utils/app_theme.dart';

class CustomCategoryScreen extends StatefulWidget {
  const CustomCategoryScreen({super.key});

  @override
  State<CustomCategoryScreen> createState() => _CustomCategoryScreenState();
}

class _CustomCategoryScreenState extends State<CustomCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _unitController = TextEditingController(text: 'cm');
  
  Color _selectedColor = AppTheme.primaryColor;
  IconData _selectedIcon = Icons.star;

  final List<Color> _colors = [
    Color(0xFFF44336), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFFC107), // Amber
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
  ];

  final List<IconData> _icons = [
    Icons.star,
    Icons.favorite,
    Icons.fitness_center,
    Icons.directions_run,
    Icons.pool,
    Icons.self_improvement,
    Icons.spa,
    Icons.bolt,
    Icons.local_fire_department,
    Icons.monitor_weight,
    Icons.straighten,
    Icons.accessibility_new,
    Icons.checkroom,
    Icons.restaurant,
    Icons.local_drink,
    Icons.bed,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final type = title.toLowerCase().replaceAll(' ', '_');
      final unit = _unitController.text.trim();

      // Check for duplicates
      final provider = context.read<AppProvider>();
      if (provider.allGuides.any((g) => g.type == type)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A category with this name already exists')),
        );
        return;
      }

      final newGuide = MeasurementGuide(
        type: type,
        title: title,
        description: 'Custom measurement for $title',
        instruction: 'Measure your $title consistently.',
        icon: _selectedIcon,
        color: _selectedColor,
        unit: unit,
        isCustom: true,
      );

      try {
        await provider.addCustomGuide(newGuide);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding category: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Custom Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Left Bicep',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g., cm, %, kg',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Create Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
