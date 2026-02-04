import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  int _selectedInterval = 30;

  final List<Map<String, dynamic>> _options = [
    {'label': 'Off', 'days': 0},
    {'label': 'Weekly', 'days': 7},
    {'label': 'Bi-weekly', 'days': 14},
    {'label': 'Monthly', 'days': 30},
    {'label': 'Quarterly', 'days': 90},
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppProvider>().settings;
    if (settings != null) {
      _selectedInterval = settings.reminderIntervalDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stay consistent with your progress by setting up measurement reminders.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final isSelected = _selectedInterval == option['days'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedInterval = option['days']);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                                  width: 2,
                                ),
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              ),
                              child: isSelected 
                                  ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              option['label'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (option['days'] > 0)
                              Text(
                                'Every ${option['days']} days',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: ElevatedButton(
                onPressed: () async {
                  final provider = context.read<AppProvider>();
                  final currentSettings = provider.settings;
                  if (currentSettings != null) {
                    final newSettings = currentSettings.copyWith(
                      reminderIntervalDays: _selectedInterval,
                      updatedAt: DateTime.now(),
                    );
                    await provider.updateSettings(newSettings);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder settings saved!')),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
