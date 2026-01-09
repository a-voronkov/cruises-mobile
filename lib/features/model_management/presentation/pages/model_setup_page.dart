import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';

/// Model setup page - shown on first launch
class ModelSetupPage extends ConsumerStatefulWidget {
  const ModelSetupPage({super.key});

  @override
  ConsumerState<ModelSetupPage> createState() => _ModelSetupPageState();
}

class _ModelSetupPageState extends ConsumerState<ModelSetupPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Preparing download...';
    });

    // TODO: Implement actual download logic
    // Simulate download for now
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _downloadProgress = i / 100;
          _statusMessage = 'Downloading model... ${i}%';
        });
      }
    }

    if (mounted) {
      setState(() {
        _statusMessage = 'Download complete!';
      });

      // Navigate to chat after a short delay
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Navigate to chat page
    }
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

              // Download progress
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _downloadProgress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Download button
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
            ],
          ),
        ),
      ),
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

