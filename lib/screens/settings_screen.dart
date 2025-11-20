import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'trash_screen.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Trash Section
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Trash'),
            subtitle: const Text('View and restore deleted habits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrashScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Multi-Habit Tracker v3.2.3'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Multi-Habit Tracker',
                applicationVersion: '3.2.3',
                applicationIcon: const Icon(Icons.track_changes, size: 48),
                children: [
                  const Text(
                    'A comprehensive habit tracking app with calendar views, '
                    'statistics, notes, and more.',
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: Text(themeProvider.themeModeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeProvider),
              );
            },
          ),
          const Divider(),

          // Data Section
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & Export'),
            subtitle: const Text('Export and import your habit data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Help Section
          _buildSectionHeader(context, 'Help & Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & FAQ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help section coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback feature coming soon!')),
              );
            },
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Made with ❤️ for building better habits',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark
                  ? const Color(0xFFD4AF37) // Gold for dark mode
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: AppThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: AppThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('System default'),
                subtitle: const Text('Follow system theme'),
                value: AppThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
