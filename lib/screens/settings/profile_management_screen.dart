import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileManagementScreen extends StatelessWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profiles'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final users = provider.users;
          final currentUser = provider.currentUser;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrent = user.id == currentUser?.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrent
                      ? Border.all(color: AppTheme.primaryColor, width: 2)
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: (isCurrent ? AppTheme.primaryColor : Colors.grey).withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: isCurrent ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text('${user.age} years • ${user.gender}'),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, provider, user),
                        ),
                  onTap: isCurrent ? null : () {
                    provider.setCurrentUser(user);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(isAddingProfile: true),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Profile', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppProvider provider, UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text('This will permanently delete all measurements and photos for ${user.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteUser(user.id!);
    }
  }
}
