import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/model_info.dart';
import '../../../../core/providers/model_download_providers.dart';
import '../../../../core/services/ai_service_provider.dart';
import '../../../../core/providers/model_status_provider.dart';
import '../../../chat/presentation/pages/chat_page.dart';

/// Model setup page - shown on first launch
class ModelSetupPage extends ConsumerStatefulWidget {
  const ModelSetupPage({super.key});

  @override
  ConsumerState<ModelSetupPage> createState() => _ModelSetupPageState();
}

class _ModelSetupPageState extends ConsumerState<ModelSetupPage> {
  bool _isInitializingModel = false;

  Future<void> _initializeAndGoToChat() async {
    if (_isInitializingModel) return;

    setState(() {
      _isInitializingModel = true;
    });

    // Cloud-based AI service is always ready, no initialization needed
    await Future.delayed(const Duration(milliseconds: 500)); // Brief delay for UX

    if (!mounted) return;

    setState(() {
      _isInitializingModel = false;
    });

    // Invalidate model status to trigger navigation.
    ref.invalidate(modelStatusProvider);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ChatPage()),
    );
  }

  Future<void> _downloadAndContinue(ModelInfo model) async {
    if (_isInitializingModel) return;

    final success = await ref.read(modelDownloadNotifierProvider.notifier).downloadModel(model);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
      return;
    }

    // Ensure the just-downloaded model is selected before initialization.
    await ref.read(modelDownloadServiceProvider).selectModel(model);
    if (!mounted) return;

    await _initializeAndGoToChat();
  }

  Future<void> _selectAndContinue(ModelInfo model) async {
    if (_isInitializingModel) return;

    final service = ref.read(modelDownloadServiceProvider);
    await service.selectModel(model);
    if (!mounted) return;

    setState(() {}); // Update selected marker.
    await _initializeAndGoToChat();
  }

  void _cancelDownload() {
    ref.read(modelDownloadNotifierProvider.notifier).cancelDownload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manifestAsync = ref.watch(modelManifestProvider);
    final downloadedModelsAsync = ref.watch(downloadedModelsProvider);
    final downloadState = ref.watch(modelDownloadNotifierProvider);
    final downloadService = ref.watch(modelDownloadServiceProvider);
    final selectedFileName = downloadService.currentModelFileName;

    return Scaffold(
      body: SafeArea(
        child: manifestAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(theme, error),
          data: (manifest) {
            if (manifest == null) {
              return _buildErrorState(theme, 'Failed to load models');
            }

            return downloadedModelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildContent(
                theme: theme,
                manifest: manifest,
                downloadedModels: const [],
                downloadState: downloadState,
                selectedFileName: selectedFileName,
              ),
              data: (downloaded) => _buildContent(
                theme: theme,
                manifest: manifest,
                downloadedModels: downloaded,
                downloadState: downloadState,
                selectedFileName: selectedFileName,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load models', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(modelManifestProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required ThemeData theme,
    required ModelManifest manifest,
    required List<String> downloadedModels,
    required ModelDownloadState downloadState,
    required String selectedFileName,
  }) {
    if (_isInitializingModel) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.sailing, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Choose an AI model',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The model is downloaded once and stored on your device for offline use.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: manifest.models.length,
              itemBuilder: (context, index) {
                final model = manifest.models[index];
                final isDownloaded = downloadedModels.contains(model.fileName);
                final isSelected = model.fileName == selectedFileName;
                final isDownloading = downloadState.isDownloading &&
                    downloadState.downloadingModelId == model.id;

                return _ModelCard(
                  model: model,
                  isDownloaded: isDownloaded,
                  isSelected: isSelected,
                  isDownloading: isDownloading,
                  downloadProgress: isDownloading ? downloadState.progress : 0,
                  downloadStatus: isDownloading ? downloadState.status : '',
                  onDownload: () => _downloadAndContinue(model),
                  onUse: isDownloaded ? () => _selectAndContinue(model) : null,
                  onContinue: isDownloaded && isSelected ? _initializeAndGoToChat : null,
                  onCancel: isDownloading ? _cancelDownload : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isDownloaded;
  final bool isSelected;
  final bool isDownloading;
  final double downloadProgress;
  final String downloadStatus;
  final VoidCallback onDownload;
  final VoidCallback? onUse;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  const _ModelCard({
    required this.model,
    required this.isDownloaded,
    required this.isSelected,
    required this.isDownloading,
    required this.downloadProgress,
    required this.downloadStatus,
    required this.onDownload,
    this.onUse,
    this.onContinue,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (model.recommended)
                  _pill(theme, 'Recommended', theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _pill(theme, 'Selected', theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              model.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(theme, Icons.storage, model.formattedSize),
                _chip(theme, Icons.memory, model.quantization),
              ],
            ),
            const SizedBox(height: 12),
            if (isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: downloadProgress),
                  const SizedBox(height: 8),
                  Text(downloadStatus, style: theme.textTheme.bodySmall),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: onCancel, child: const Text('Cancel')),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isDownloaded)
                    FilledButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    )
                  else ...[
                    if (onContinue != null)
                      FilledButton(
                        onPressed: onContinue,
                        child: const Text('Continue'),
                      )
                    else
                      FilledButton(
                        onPressed: onUse,
                        child: const Text('Use this model'),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  static Widget _pill(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}

