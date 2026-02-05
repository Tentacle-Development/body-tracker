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
    final savedTabs = provider.settings?.enabledTabs ?? 
        ['dashboard', 'measure', 'photos', 'progress', 'sizes', 'profile'];
    
    _enabledTabs = List.from(savedTabs);

    // Sort _allTabs based on saved order (enabled first in order, then others)
    _allTabs.sort((a, b) {
      final indexA = savedTabs.indexOf(a['id'] as String);
      final indexB = savedTabs.indexOf(b['id'] as String);
      
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return 0;
    });
  }

  void _save() {
    if (!_enabledTabs.contains('profile')) {
      _enabledTabs.add('profile');
    }

    if (_enabledTabs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one tab must be enabled')),
      );
      return;
    }
    
    final provider = context.read<AppProvider>();
    final newSettings = provider.settings!.copyWith(enabledTabs: _enabledTabs);
    provider.updateSettings(newSettings);
    
    // Explicitly notify provider to refresh
    provider.loadSettings();

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
              'Drag to reorder. Deactivated tabs appear in the Profile menu.',
              textAlign: TextAlign.center,
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
                  
                  _updateEnabledTabsOrder();
                });
              },
              itemCount: _allTabs.length,
              itemBuilder: (context, index) {
                final tab = _allTabs[index];
                final id = tab['id'] as String;
                final isEnabled = _enabledTabs.contains(id);
                final isProfile = id == 'profile';

                return ListTile(
                  key: ValueKey(id),
                  leading: const Icon(Icons.drag_handle, color: Colors.grey),
                  title: Row(
                    children: [
                      Icon(tab['icon'] as IconData, size: 20, color: isEnabled ? AppTheme.primaryColor : Colors.grey),
                      const SizedBox(width: 12),
                      Text(tab['label'] as String, style: TextStyle(color: isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary)),
                    ],
                  ),
                  trailing: Checkbox(
                    value: isEnabled,
                    onChanged: isProfile ? null : (value) {
                      setState(() {
                        if (value == true) {
                          _enabledTabs.add(id);
                        } else {
                          if (_enabledTabs.length > 1) {
                            _enabledTabs.remove(id);
                          }
                        }
                        _updateEnabledTabsOrder();
                      });
                    },
                    activeColor: isProfile ? Colors.grey : AppTheme.primaryColor,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _updateEnabledTabsOrder() {
    final List<String> newOrder = [];
    for (var tab in _allTabs) {
      if (_enabledTabs.contains(tab['id'])) {
        newOrder.add(tab['id'] as String);
      }
    }
    _enabledTabs = newOrder;
  }
}
