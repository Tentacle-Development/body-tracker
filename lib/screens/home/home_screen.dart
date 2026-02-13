import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  Widget _buildNavItem(String tabId, IconData icon, IconData activeIcon, String label, bool isSelected, VoidCallback onTap) {
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
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
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final enabledTabs = settings?.enabledTabs ?? 
            ['dashboard', 'measure', 'photos', 'progress', 'sizes', 'profile'];

        final List<Widget> tabScreens = [];
        final List<Widget> navItems = [];
        
        String activeTabId = provider.activeTabId;
        if (!enabledTabs.contains(activeTabId)) {
          activeTabId = enabledTabs.first;
        }

        int activeIndex = 0;

        for (int i = 0; i < enabledTabs.length; i++) {
          final tabId = enabledTabs[i].trim();
          final isSelected = activeTabId == tabId;
          if (isSelected) activeIndex = i;

          switch (tabId) {
            case 'dashboard':
              tabScreens.add(const DashboardTab());
              navItems.add(_buildNavItem(tabId, Icons.dashboard_outlined, Icons.dashboard, l10n.dashboard, isSelected, () => provider.setActiveTab(tabId)));
              break;
            case 'measure':
              tabScreens.add(const MeasurementsTab());
              navItems.add(_buildNavItem(tabId, Icons.straighten_outlined, Icons.straighten, l10n.measure, isSelected, () => provider.setActiveTab(tabId)));
              break;
            case 'photos':
              tabScreens.add(const PhotoGalleryScreen());
              navItems.add(_buildNavItem(tabId, Icons.photo_camera_outlined, Icons.photo_camera, l10n.photos, isSelected, () => provider.setActiveTab(tabId)));
              break;
            case 'progress':
              tabScreens.add(const ProgressChartsTab());
              navItems.add(_buildNavItem(tabId, Icons.show_chart_outlined, Icons.show_chart, l10n.progress, isSelected, () => provider.setActiveTab(tabId)));
              break;
            case 'sizes':
              tabScreens.add(const ClothingSizeScreen());
              navItems.add(_buildNavItem(tabId, Icons.checkroom_outlined, Icons.checkroom, l10n.sizes, isSelected, () => provider.setActiveTab(tabId)));
              break;
            case 'profile':
              tabScreens.add(const ProfileTab());
              navItems.add(_buildNavItem(tabId, Icons.person_outline, Icons.person, l10n.profile, isSelected, () => provider.setActiveTab(tabId)));
              break;
          }
        }

        return Scaffold(
          key: ValueKey('home_scaffold_${settings?.updatedAt.millisecondsSinceEpoch ?? 0}'),
          body: IndexedStack(
            key: ValueKey('stack_${settings?.updatedAt.millisecondsSinceEpoch ?? 0}'),
            index: activeIndex,
            children: tabScreens.isEmpty ? [const Center(child: CircularProgressIndicator())] : tabScreens,
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
                  key: ValueKey('nav_row_${settings?.updatedAt.millisecondsSinceEpoch ?? 0}'),
                  mainAxisSize: MainAxisSize.min,
                  children: navItems,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboard,
                  style: const TextStyle(
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
                      childAspectRatio: 0.85,
                    ),
                    itemCount: provider.dashboardCategories.length,
                    itemBuilder: (context, index) {
                      final cat = provider.dashboardCategories[index];
                      if (cat == 'bmi') {
                        return _buildStatCard(
                          context,
                          l10n.bmi,
                          bmi?.toStringAsFixed(1) ?? '--',
                          _getBMICategory(context, bmi),
                          Icons.monitor_weight_outlined,
                          AppTheme.primaryColor,
                          onTap: () {
                            final weightGuide = MeasurementGuide.guides.firstWhere((g) => g.type == 'weight');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementDetailScreen(
                                  guide: weightGuide,
                                ),
                              ),
                            );
                          },
                        );
                      } else if (cat == 'whr') {
                        return _buildStatCard(
                          context,
                          l10n.waistHip,
                          whr?.toStringAsFixed(2) ?? '--',
                          _getWHRCategory(context, whr, provider.currentUser?.gender),
                          Icons.accessibility_new,
                          AppTheme.secondaryColor,
                          onTap: () {
                            final waistGuide = provider.allGuides.firstWhere((g) => g.type == 'waist');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MeasurementDetailScreen(
                                  guide: waistGuide,
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        final guide = provider.allGuides.firstWhere(
                          (g) => g.type == cat,
                          orElse: () => MeasurementGuide.guides.first, // Fallback to avoid crash
                        );
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBMICategory(BuildContext context, double? bmi) {
    final l10n = AppLocalizations.of(context)!;
    if (bmi == null) return l10n.noData;
    if (bmi < 18.5) return l10n.underweight;
    if (bmi < 25) return l10n.normal;
    if (bmi < 30) return l10n.overweight;
    return l10n.obese;
  }

  String _getWHRCategory(BuildContext context, double? whr, String? gender) {
    final l10n = AppLocalizations.of(context)!;
    if (whr == null) return l10n.noData;
    if (gender == 'Male') {
      if (whr < 0.9) return l10n.lowRisk;
      if (whr < 1.0) return l10n.moderateRisk;
      return l10n.highRisk;
    } else {
      if (whr < 0.8) return l10n.lowRisk;
      if (whr < 0.85) return l10n.moderateRisk;
      return l10n.highRisk;
    }
  }
}

class MeasurementsTab extends StatelessWidget {
  const MeasurementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.measurements,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomCategoryScreen()),
                    );
                  },
                ),
              ],
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
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Text(l10n.newMeasurement, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    itemCount: provider.allGuides.length,
                    itemBuilder: (context, index) {
                      final guide = provider.allGuides[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeasurementDetailScreen(guide: guide))),
                        onLongPress: guide.isCustom ? () => _showDeleteDialog(context, provider, guide) : null,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(guide.icon, color: guide.color, size: 24),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      guide.title, 
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (guide.isCustom)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
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

  void _showDeleteDialog(BuildContext context, AppProvider provider, MeasurementGuide guide) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(l10n.deleteCategoryConfirm(guide.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (guide.id != null) {
                await provider.deleteCustomGuide(guide.id!);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profile, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                          Text(l10n.yearsOld(user.age), style: const TextStyle(color: AppTheme.textSecondary)),
                        ]),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              Text(l10n.settings, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              
              _buildSettingsItem(context, icon: Icons.navigation_outlined, title: l10n.navigation, subtitle: l10n.customizeBottomBar, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NavigationSettingsScreen()));
              }),
              const SizedBox(height: 12),
              _buildSettingsItem(context, icon: Icons.notifications_active_outlined, title: l10n.reminders, subtitle: l10n.setupNotifications, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()));
              }),
              const SizedBox(height: 12),
              _buildSettingsItem(context, icon: Icons.flag_outlined, title: l10n.goals, subtitle: l10n.trackTargets, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
              }),
              const SizedBox(height: 12),
              _buildSettingsItem(context, icon: Icons.backup_rounded, title: l10n.backupAndRestore, subtitle: l10n.dataManagement, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
              }),

              // Extra Features
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final l10n = AppLocalizations.of(context)!;
                  final enabledTabs = provider.settings?.enabledTabs ?? [];
                  final List<Widget> extraItems = [];
                  
                  if (!enabledTabs.contains('dashboard')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.dashboard_outlined, title: l10n.dashboard, subtitle: l10n.overview, onTap: () {}));
                  }
                  if (!enabledTabs.contains('measure')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.straighten_outlined, title: l10n.measure, subtitle: l10n.newEntries, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuidedMeasurementFlow()));
                    }));
                  }
                  if (!enabledTabs.contains('photos')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.photo_camera_outlined, title: l10n.photos, subtitle: l10n.gallery, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhotoGalleryScreen()));
                    }));
                  }
                  if (!enabledTabs.contains('progress')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.show_chart_outlined, title: l10n.progress, subtitle: l10n.charts, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressChartsTab()));
                    }));
                  }
                  if (!enabledTabs.contains('sizes')) {
                    extraItems.add(_buildSettingsItem(context, icon: Icons.checkroom_outlined, title: l10n.sizes, subtitle: l10n.clothingGuide, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClothingSizeScreen()));
                    }));
                  }

                  if (extraItems.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(l10n.extraFeatures, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
