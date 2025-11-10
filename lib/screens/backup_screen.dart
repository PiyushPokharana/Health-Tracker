import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../providers/habit_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;

  Future<void> _exportData() async {
    setState(() => _isProcessing = true);

    try {
      await _backupService.saveAndShareBackup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Backup file created and ready to share!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF50C878),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Export failed: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF5350),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importData() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text(
          'This will import habits and records from a backup file. '
          'Existing habits with the same name will not be duplicated, '
          'but new records will be added.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _backupService.pickAndImportBackup();

      if (!mounted) return;

      // Refresh the habit list
      await context.read<HabitProvider>().loadHabits();

      // Show success message with details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF50C878)),
              SizedBox(width: 12),
              Text('Import Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓ ${result['habitsImported']} new habits imported'),
              if (result['habitsDuplicate'] > 0)
                Text(
                    '• ${result['habitsDuplicate']} habits already existed (skipped)'),
              Text('✓ ${result['recordsImported']} records imported'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Import failed: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF5350),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Export'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Data',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a backup of all your habits and records',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? const Color(0xFFB0B0B0)
                                        : Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _exportData,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                          _isProcessing ? 'Exporting...' : 'Export Backup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The backup file will be saved and you can share it via any app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF808080)
                              : Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Import Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cloud_download_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Data',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Restore from a previously saved backup file',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? const Color(0xFFB0B0B0)
                                        : Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _importData,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(
                          _isProcessing ? 'Importing...' : 'Import Backup'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select a .json backup file to restore your data.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF808080)
                              : Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Information Card
          Card(
            color: isDark ? const Color(0xFF1A2332) : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? const Color(0xFFD4AF37)
                            : Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About Backups',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : Colors.blue.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Backup files contain all your habits and tracking records\n'
                    '• Data is saved in JSON format for easy portability\n'
                    '• Import will not duplicate existing habits with the same name\n'
                    '• New records from backups will be added to existing habits\n'
                    '• Store backups safely to prevent data loss',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.6,
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : Colors.grey[700],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
