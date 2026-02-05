import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class NavigationSettingsScreen extends StatefulWidget {
  const NavigationSettingsScreen({super.key});

  @override
  State<NavigationSettingsScreen> createState() => _NavigationSettingsScreenState();
}

class _NavigationSettingsScreenState extends State<NavigationSettingsScreen> {
  final List<Map<String, dynamic>> _allTabs = [
    {'id': 'dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard},
    {'id': 'measure', 'label': 'Measure', 'icon': Icons.straighten},
    {'id': 'photos', 'label': 'Photos', 'icon': Icons.photo_camera},
    {'id': 'progress', 'label': 'Progress', 'icon': Icons.show_chart},
    {'id': 'sizes', 'label': 'Sizes', 'icon': Icons.checkroom},
    {'id': 'profile', 'label': 'Profile', 'icon': Icons.person},
  ];

  late List<String> _enabledTabs;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _enabledTabs = List.from(provider.settings?.enabledTabs ?? 
        ['dashboard', 'measure', 'photos', 'progress', 'sizes', 'profile']);
  }

  void _save() {
    if (_enabledTabs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one tab must be enabled')),
      );
      return;
    }
    
    final provider = context.read<AppProvider>();
    final newSettings = provider.settings!.copyWith(enabledTabs: _enabledTabs);
    provider.updateSettings(newSettings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Navigation'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select which tabs to show in the bottom bar and drag to reorder.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _allTabs.removeAt(oldIndex);
                  _allTabs.insert(newIndex, item);
                  
                  // Update enabled tabs list to match new order
                  _updateEnabledTabsOrder();
                });
              },
              itemCount: _allTabs.length,
              itemBuilder: (context, index) {
                final tab = _allTabs[index];
                final id = tab['id'] as String;
                final isEnabled = _enabledTabs.contains(id);

                return ListTile(
                  key: ValueKey(id),
                  leading: const Icon(Icons.drag_handle, color: Colors.grey),
                  title: Row(
                    children: [
                      Icon(tab['icon'] as IconData, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(tab['label'] as String),
                    ],
                  ),
                  trailing: Checkbox(
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          if (!_enabledTabs.contains(id)) {
                            _enabledTabs.add(id);
                            _updateEnabledTabsOrder();
                          }
                        } else {
                          if (_enabledTabs.length > 1) {
                            _enabledTabs.remove(id);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('At least one tab must remain enabled')),
                            );
                          }
                        }
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateEnabledTabsOrder() {
    // Keep enabled tabs but in the order they appear in _allTabs
    final List<String> newOrder = [];
    for (var tab in _allTabs) {
      if (_enabledTabs.contains(tab['id'])) {
        newOrder.add(tab['id'] as String);
      }
    }
    _enabledTabs = newOrder;
  }
}
