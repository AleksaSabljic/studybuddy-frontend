import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: scheme.primary,
              child: Text(
                (user?.username ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(user?.username ?? '',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(user?.email ?? '',
                style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: user?.isGroupLeader == true
                    ? scheme.primaryContainer
                    : scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.isGroupLeader == true ? 'Group Leader' : 'Student',
                style: TextStyle(
                    color: user?.isGroupLeader == true
                        ? scheme.onPrimaryContainer
                        : scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),

          // Dark mode toggle
          ListTile(
            leading: Icon(
                theme.isDark ? Icons.light_mode : Icons.dark_mode,
                color: scheme.primary),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
            ),
          ),
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: scheme.primary),
            title: const Text('Study Location'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.location),
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),

          const SizedBox(height: 24),
          Center(
            child: Text('StudyBuddy v1.0.0',
                style: TextStyle(
                    color: scheme.onSurface.withOpacity(.4), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
