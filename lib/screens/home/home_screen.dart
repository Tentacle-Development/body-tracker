import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/measurement_guide.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../measurements/guided_measurement_flow.dart';
import '../measurements/measurement_input_screen.dart';
import '../measurements/measurement_detail_screen.dart';
import '../photos/photo_gallery_screen.dart';
import 'progress_charts_tab.dart';
import '../settings/backup_restore_screen.dart';
import '../settings/dashboard_customize_screen.dart';
import '../settings/reminder_settings_screen.dart';
import '../settings/reminder_settings_screen.dart';
import '../settings/goals_screen.dart';
import '../settings/clothing_size_screen.dart';
import '../settings/profile_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardTab(),
          MeasurementsTab(),
          PhotoGalleryScreen(),
          ProgressChartsTab(),
          ClothingSizeScreen(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Ensure row doesn't force items to stretch
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.straighten_outlined, Icons.straighten, 'Measure'),
                _buildNavItem(2, Icons.photo_camera_outlined, Icons.photo_camera, 'Photos'),
                _buildNavItem(3, Icons.show_chart_outlined, Icons.show_chart, 'Progress'),
                _buildNavItem(4, Icons.checkroom_outlined, Icons.checkroom, 'Sizes'),
                _buildNavItem(5, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondary;

    return GestureDetector( // Using GestureDetector instead of InkWell for more control
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 85, // Slightly wider to avoid truncation
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent, // Make entire area tappable
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible, // Don't truncate labels
              style: TextStyle(
                color: color,
                fontSize: 11, // Slightly smaller font to fit
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DashboardCustomizeScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final bmi = provider.calculateBMI();
                  final whr = provider.calculateWaistToHipRatio();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.dashboardCategories.length,
                    itemBuilder: (context, index) {
                      final cat = provider.dashboardCategories[index];
                      if (cat == 'bmi') {
                        return _buildStatCard(
                          context,
                          'BMI',
                          bmi?.toStringAsFixed(1) ?? '--',
                          _getBMICategory(bmi),
                          Icons.monitor_weight_outlined,
                          AppTheme.primaryColor,
                          onTap: () {
                            final weightGuide = MeasurementGuide.guides.firstWhere((g) => g.type == 'weight');
                            final weightHistory = provider.getMeasurementsByType('weight');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementDetailScreen(
                                  guide: weightGuide,
                                  history: weightHistory,
                                ),
                              ),
                            );
                          },
                        );
                      } else if (cat == 'whr') {
                        return _buildStatCard(
                          context,
                          'Waist/Hip',
                          whr?.toStringAsFixed(2) ?? '--',
                          _getWHRCategory(whr, provider.currentUser?.gender),
                          Icons.accessibility_new,
                          AppTheme.secondaryColor,
                          onTap: () {
                            final waistGuide = MeasurementGuide.guides.firstWhere((g) => g.type == 'waist');
                            final waistHistory = provider.getMeasurementsByType('waist');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementDetailScreen(
                                  guide: waistGuide,
                                  history: waistHistory,
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        final guide = MeasurementGuide.guides.firstWhere((g) => g.type == cat);
                        final history = provider.getMeasurementsByType(cat);
                        final latest = provider.getLatestMeasurement(cat);

                        return _buildStatCard(
                          context,
                          guide.title,
                          latest?.value.toStringAsFixed(1) ?? '--',
                          latest?.unit ?? guide.unit,
                          guide.icon,
                          guide.color,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementDetailScreen(
                                  guide: guide,
                                  history: history,
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBMICategory(double? bmi) {
    if (bmi == null) return 'No data';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _getWHRCategory(double? whr, String? gender) {
    if (whr == null) return 'No data';
    if (gender == 'Male') {
      if (whr < 0.9) return 'Low risk';
      if (whr < 1.0) return 'Moderate risk';
      return 'High risk';
    } else {
      if (whr < 0.8) return 'Low risk';
      if (whr < 0.85) return 'Moderate risk';
      return 'High risk';
    }
  }
}

class MeasurementsTab extends StatelessWidget {
  const MeasurementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Measurements',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your body measurements',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Quick add button
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GuidedMeasurementFlow(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Body Measurement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Guided step-by-step measurement',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick measurements
            const Text(
              'Quick Add',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: MeasurementGuide.guides.length,
                    itemBuilder: (context, index) {
                      final guide = MeasurementGuide.guides[index];
                      final latest = provider.getLatestMeasurement(guide.type);
                      final history = provider.getMeasurementsByType(guide.type);

                      return GestureDetector(
                        onTap: () {
                          if (latest == null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementInputScreen(guide: guide),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementDetailScreen(
                                  guide: guide,
                                  history: history,
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: latest != null ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MeasurementInputScreen(guide: guide),
                            ),
                          );
                        } : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: guide.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  guide.icon,
                                  color: guide.color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                guide.title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (latest != null)
                                Text(
                                  '${latest.value.toStringAsFixed(0)} ${guide.unit}',
                                  style: TextStyle(
                                    color: guide.color,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SizesTab extends StatelessWidget {
  const SizesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Clothing Sizes Tab\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                final user = provider.currentUser;
                if (user == null) {
                  return const Center(child: Text('No profile found'));
                }
                
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileManagementScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${user.age} years old • ${user.gender}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.swap_horiz, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSettingsItem(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Reminders',
              subtitle: 'Setup measurement notifications',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReminderSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            _buildSettingsItem(
              context,
              icon: Icons.flag_outlined,
              title: 'My Goals',
              subtitle: 'Track your body targets',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GoalsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            _buildSettingsItem(
              context,
              icon: Icons.backup_rounded,
              title: 'Backup & Restore',
              subtitle: 'Export or import your data',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BackupRestoreScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
