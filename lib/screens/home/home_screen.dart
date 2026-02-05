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
import '../settings/goals_screen.dart';
import '../settings/clothing_size_screen.dart';
import '../settings/navigation_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final enabledTabs = provider.settings?.enabledTabs ?? 
        ['dashboard', 'measure', 'photos', 'progress', 'sizes', 'profile'];

    final List<Widget> tabScreens = [];
    final List<Widget> navItems = [];

    for (int i = 0; i < enabledTabs.length; i++) {
      final tabId = enabledTabs[i];
      switch (tabId) {
        case 'dashboard':
          tabScreens.add(const DashboardTab());
          navItems.add(_buildNavItem(i, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'));
          break;
        case 'measure':
          tabScreens.add(const MeasurementsTab());
          navItems.add(_buildNavItem(i, Icons.straighten_outlined, Icons.straighten, 'Measure'));
          break;
        case 'photos':
          tabScreens.add(const PhotoGalleryScreen());
          navItems.add(_buildNavItem(i, Icons.photo_camera_outlined, Icons.photo_camera, 'Photos'));
          break;
        case 'progress':
          tabScreens.add(const ProgressChartsTab());
          navItems.add(_buildNavItem(i, Icons.show_chart_outlined, Icons.show_chart, 'Progress'));
          break;
        case 'sizes':
          tabScreens.add(const ClothingSizeScreen());
          navItems.add(_buildNavItem(i, Icons.checkroom_outlined, Icons.checkroom, 'Sizes'));
          break;
        case 'profile':
          tabScreens.add(const ProfileTab());
          navItems.add(_buildNavItem(i, Icons.person_outline, Icons.person, 'Profile'));
          break;
      }
    }

    if (_currentIndex >= tabScreens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabScreens,
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
              mainAxisSize: MainAxisSize.min,
              children: navItems,
            ),
          ),
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
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GuidedMeasurementFlow()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 28),
                    SizedBox(width: 16),
                    Text('New Measurement', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: MeasurementGuide.guides.length,
                    itemBuilder: (context, index) {
                      final guide = MeasurementGuide.guides[index];
                      final latest = provider.getLatestMeasurement(guide.type);
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeasurementDetailScreen(guide: guide, history: provider.getMeasurementsByType(guide.type)))),
                        child: Container(
                          decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(guide.icon, color: guide.color, size: 24),
                              const SizedBox(height: 8),
                              Text(guide.title, style: const TextStyle(fontSize: 12)),
                              if (latest != null) Text('${latest.value}${guide.unit}', style: TextStyle(color: guide.color, fontSize: 10)),
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

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final user = provider.currentUser;
                  if (user == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: AppTheme.primaryColor, child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${user.age} years old', style: const TextStyle(color: AppTheme.textSecondary)),
                        ]),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              const Text('Settings', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              
              _buildSettingsItem(context, icon: Icons.navigation_outlined, title: 'Navigation', subtitle: 'Customize bottom bar', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NavigationSettingsScreen()));
              }),
              const SizedBox(height: 12),
              _buildSettingsItem(context, icon: Icons.notifications_active_outlined, title: 'Reminders', subtitle: 'Setup notifications', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()));
              }),
              const SizedBox(height: 12),
              _buildSettingsItem(context, icon: Icons.flag_outlined, title: 'Goals', subtitle: 'Track targets', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
              }),
              const SizedBox(height: 12),
              _buildSettingsItem(context, icon: Icons.backup_rounded, title: 'Backup & Restore', subtitle: 'Data management', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
              }),

              // Extra Features
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final enabledTabs = provider.settings?.enabledTabs ?? [];
                  final List<Widget> extraItems = [];
                  
                  if (!enabledTabs.contains('dashboard')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.dashboard_outlined, title: 'Dashboard', subtitle: 'Overview', onTap: () {}));
                  }
                  if (!enabledTabs.contains('measure')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.straighten_outlined, title: 'Measure', subtitle: 'New entries', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuidedMeasurementFlow()));
                    }));
                  }
                  if (!enabledTabs.contains('photos')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.photo_camera_outlined, title: 'Photos', subtitle: 'Gallery', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhotoGalleryScreen()));
                    }));
                  }
                  if (!enabledTabs.contains('progress')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.show_chart_outlined, title: 'Progress', subtitle: 'Charts', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressChartsTab()));
                    }));
                  }
                  if (!enabledTabs.contains('sizes')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.checkroom_outlined, title: 'Sizes', subtitle: 'Clothing guide', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClothingSizeScreen()));
                    }));
                  }

                  if (extraItems.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text('Extra Features', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 12),
                      ...extraItems.expand((item) => [item, const SizedBox(height: 12)]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
