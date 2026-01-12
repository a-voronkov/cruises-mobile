import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/model_download_service.dart';
import '../../../../main.dart';
import '../providers/settings_provider.dart';

/// Settings page
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Appearance section
                _buildSectionHeader(context, 'Appearance'),
                _buildThemeTile(context, ref, settings.themeMode),
                const Divider(),

                // Model section
                _buildSectionHeader(context, 'AI Model'),
                _buildModelInfoTile(context),
                _buildRedownloadModelTile(context, ref),
                const Divider(),

                // Storage section
                _buildSectionHeader(context, 'Storage'),
                _buildClearDataTile(context, ref),
                const Divider(),

                // About section
                _buildSectionHeader(context, 'About'),
                _buildAboutTile(context),
                _buildVersionTile(context),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Theme'),
      subtitle: Text(_themeModeToString(currentMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref, currentMode),
    );
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_themeModeToString(mode)),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  // Also update legacy provider for immediate effect
                  ref.read(themeModeProvider.notifier).state = value;
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModelInfoTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.smart_toy_outlined),
      title: const Text('Current model'),
      subtitle: Text('${AppConstants.modelName} ${AppConstants.modelVersion}'),
    );
  }

  Widget _buildRedownloadModelTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.download_outlined),
      title: const Text('Re-download model'),
      subtitle: const Text('Download the AI model again'),
      onTap: () => _showRedownloadDialog(context, ref),
    );
  }

  void _showRedownloadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-download model?'),
        content: const Text(
          'This will delete the current model and download it again. '
          'Make sure you have a stable internet connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ModelDownloadService();
              await service.deleteModel();
              ref.invalidate(modelStatusProvider);
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Re-download'),
          ),
        ],
      ),
    );
  }

  Widget _buildClearDataTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
      title: Text(
        'Clear all data',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      subtitle: const Text('Delete all conversations and settings'),
      onTap: () => _showClearDataDialog(context, ref),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete all your conversations and settings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About'),
      subtitle: const Text('Cruises Assistant'),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'Cruises Assistant',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.sailing, size: 48),
          children: [
            const Text(
              'Your AI-powered travel planning companion for cruise vacations.',
            ),
          ],
        );
      },
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    return const ListTile(
      leading: Icon(Icons.tag),
      title: Text('Version'),
      subtitle: Text('1.0.0'),
    );
  }
}
