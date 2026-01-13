import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/model_info.dart';
import '../../../../main.dart';
import '../providers/model_manifest_provider.dart';

/// Page for selecting and downloading AI models
class ModelSelectionPage extends ConsumerWidget {
  const ModelSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestAsync = ref.watch(modelManifestProvider);
    final downloadedModelsAsync = ref.watch(downloadedModelsProvider);
    final downloadState = ref.watch(modelDownloadNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
      ),
      body: manifestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error),
        data: (manifest) {
          if (manifest == null) {
            return _buildErrorState(context, ref, 'Failed to load models');
          }
          return downloadedModelsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildModelList(context, ref, manifest, [], downloadState),
            data: (downloaded) => _buildModelList(context, ref, manifest, downloaded, downloadState),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load models', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
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

  Widget _buildModelList(BuildContext context, WidgetRef ref, ModelManifest manifest, List<String> downloadedModels, ModelDownloadState downloadState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: manifest.models.length,
      itemBuilder: (context, index) {
        final model = manifest.models[index];
        final isDownloaded = downloadedModels.contains(model.fileName);
        final isDownloading = downloadState.isDownloading && downloadState.downloadingModelId == model.id;
        return _ModelCard(
          model: model,
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
          downloadProgress: isDownloading ? downloadState.progress : 0,
          downloadStatus: isDownloading ? downloadState.status : '',
          onDownload: () => _startDownload(context, ref, model),
          onDelete: () => _showDeleteDialog(context, ref, model),
          onSelect: isDownloaded ? () => _selectModel(context, ref, model) : null,
        );
      },
    );
  }

  Future<void> _startDownload(BuildContext context, WidgetRef ref, ModelInfo model) async {
    final success = await ref.read(modelDownloadNotifierProvider.notifier).downloadModel(model);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Model downloaded!' : 'Download failed'), backgroundColor: success ? Colors.green : Colors.red),
      );
    }
  }

  void _selectModel(BuildContext context, WidgetRef ref, ModelInfo model) {
    final service = ref.read(modelDownloadServiceProvider);
    service.selectModel(model);
    ref.invalidate(modelStatusProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: ${model.name}')));
    Navigator.pop(context);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ModelInfo model) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text('Delete ${model.name}? (${model.formattedSize})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = await ref.read(modelDownloadNotifierProvider.notifier).deleteModel(model);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(deleted ? 'Model deleted' : 'Failed to delete')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


/// Card widget for displaying a single model
class _ModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final String downloadStatus;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback? onSelect;

  const _ModelCard({
    required this.model,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.downloadStatus,
    required this.onDownload,
    required this.onDelete,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 8),
            Text(model.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            _buildInfoRow(theme),
            const SizedBox(height: 12),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Text(model.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        if (model.recommended)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text('Recommended', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    return Row(
      children: [
        _buildChip(theme, Icons.storage, model.formattedSize),
        const SizedBox(width: 8),
        _buildChip(theme, Icons.memory, model.quantization),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ]),
    );
  }

  Widget _buildActions(ThemeData theme) {
    if (isDownloading) {
      return Column(children: [
        LinearProgressIndicator(value: downloadProgress),
        const SizedBox(height: 8),
        Text(downloadStatus, style: theme.textTheme.bodySmall),
      ]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isDownloaded) ...[
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          const SizedBox(width: 8),
          Text('Downloaded', style: theme.textTheme.bodySmall),
          const Spacer(),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onSelect, child: const Text('Select')),
        ] else
          FilledButton.icon(onPressed: onDownload, icon: const Icon(Icons.download), label: const Text('Download')),
      ],
    );
  }
}

