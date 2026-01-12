import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/model_download_provider.dart';
import '../../../../core/services/llama_service_provider.dart';
import '../../../../main.dart';
import '../../../chat/presentation/pages/chat_page.dart';

/// Model setup page - shown on first launch
class ModelSetupPage extends ConsumerStatefulWidget {
  const ModelSetupPage({super.key});

  @override
  ConsumerState<ModelSetupPage> createState() => _ModelSetupPageState();
}

class _ModelSetupPageState extends ConsumerState<ModelSetupPage> {
  bool _isInitializingModel = false;

  Future<void> _startDownload() async {
    final notifier = ref.read(modelDownloadProvider.notifier);
    final success = await notifier.startDownload();

    if (success && mounted) {
      // Initialize the LLM after successful download
      setState(() {
        _isInitializingModel = true;
      });

      final modelNotifier = ref.read(modelInitializationProvider.notifier);
      await modelNotifier.initialize();

      if (mounted) {
        setState(() {
          _isInitializingModel = false;
        });

        // Invalidate model status to trigger navigation
        ref.invalidate(modelStatusProvider);

        // Navigate to chat page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ChatPage()),
          );
        }
      }
    }
  }

  void _cancelDownload() {
    ref.read(modelDownloadProvider.notifier).cancelDownload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App icon/logo
              Icon(
                Icons.sailing,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome to Cruises Assistant',
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Your AI-powered travel planning companion',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Model info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Model Setup',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Model',
                        AppConstants.modelName,
                      ),
                      _buildInfoRow(
                        context,
                        'Version',
                        AppConstants.modelVersion,
                      ),
                      _buildInfoRow(
                        context,
                        'Size',
                        '~${(AppConstants.modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The AI model will be downloaded and stored on your device for offline use.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Download progress or button
              _buildDownloadSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadSection(ThemeData theme) {
    final downloadState = ref.watch(modelDownloadProvider);

    if (_isInitializingModel) {
      return Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Initializing AI model...',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (downloadState.isDownloading) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: downloadState.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            downloadState.statusMessage,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelDownload,
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    if (downloadState.error != null) {
      return Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            downloadState.error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: _startDownload,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Download AI Model',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Make sure you have a stable internet connection',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

