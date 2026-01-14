import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/huggingface_model_search_service.dart';
import '../../../../core/services/huggingface_model_files_service.dart';
import '../../../../core/services/ai_service_provider.dart';
import '../../../../core/models/model_info.dart';
import '../../../../core/config/api_config.dart';

/// Provider for model files service
final modelFilesServiceProvider = Provider<HuggingFaceModelFilesService>((ref) {
  return HuggingFaceModelFilesService(
    apiKey: ApiConfig.isConfigured ? ApiConfig.huggingFaceApiKey : null,
  );
});

/// State for model files loading
class ModelFilesState {
  final Map<String, List<HFModelFile>> filesByQuantization;
  final bool isLoading;
  final String? error;

  const ModelFilesState({
    this.filesByQuantization = const {},
    this.isLoading = false,
    this.error,
  });

  ModelFilesState copyWith({
    Map<String, List<HFModelFile>>? filesByQuantization,
    bool? isLoading,
    String? error,
  }) {
    return ModelFilesState(
      filesByQuantization: filesByQuantization ?? this.filesByQuantization,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for model files
class ModelFilesNotifier extends Notifier<ModelFilesState> {
  @override
  ModelFilesState build() => const ModelFilesState();

  Future<void> loadFiles(String repoId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(modelFilesServiceProvider);

      // First, get files without sizes
      debugPrint('Loading files for $repoId...');
      final files = await service.getONNXFilesByQuantization(repoId);

      // Update state with files (sizes will be fetched in background)
      state = state.copyWith(
        filesByQuantization: files,
        isLoading: false,
      );

      debugPrint('Files loaded, state updated');

      // Note: Sizes are already fetched in getONNXFilesByQuantization
      // The state update above should trigger UI rebuild with correct sizes
    } catch (e) {
      debugPrint('Error loading files: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final modelFilesProvider = NotifierProvider<ModelFilesNotifier, ModelFilesState>(
  ModelFilesNotifier.new,
);

/// Page for selecting quantization and downloading model
class ModelDownloadPage extends ConsumerStatefulWidget {
  final HFModelInfo model;

  const ModelDownloadPage({
    super.key,
    required this.model,
  });

  @override
  ConsumerState<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends ConsumerState<ModelDownloadPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modelFilesProvider.notifier).loadFiles(widget.model.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(modelFilesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.model.modelName),
      ),
      body: _buildBody(filesState, theme),
    );
  }

  Widget _buildBody(ModelFilesState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading model files...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Error', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(modelFilesProvider.notifier).loadFiles(widget.model.id);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.filesByQuantization.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('No ONNX files found', style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      );
    }

    return _buildQuantizationList(state, theme);
  }

  Widget _buildQuantizationList(ModelFilesState state, ThemeData theme) {
    if (_isDownloading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 24),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(_downloadStatus, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Repository', value: widget.model.id),
                _InfoRow(label: 'Author', value: widget.model.author),
                if (widget.model.estimatedSizeB != null)
                  _InfoRow(
                    label: 'Size',
                    value: '~${widget.model.estimatedSizeB!.toStringAsFixed(1)}B parameters',
                  ),
                if (widget.model.downloads != null)
                  _InfoRow(
                    label: 'Downloads',
                    value: _formatNumber(widget.model.downloads!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select Quantization',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lower quantization = smaller file size but lower quality',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...state.filesByQuantization.entries.map((entry) {
          return _QuantizationCard(
            quantization: entry.key,
            files: entry.value,
            onDownload: _downloadFile,
          );
        }),
      ],
    );
  }

  Future<void> _downloadFile(HFModelFile file) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Preparing download...';
    });

    try {
      final downloadService = ref.read(modelDownloadServiceProvider);

      // Calculate total files to download (main + related)
      final totalFiles = 1 + file.relatedFiles.length;
      final allFiles = [file, ...file.relatedFiles];

      setState(() {
        _downloadStatus = 'Downloading $totalFiles file${totalFiles > 1 ? 's' : ''}...';
      });

      // Download all files
      for (int i = 0; i < allFiles.length; i++) {
        final currentFile = allFiles[i];
        final fileName = currentFile.path.split('/').last;

        setState(() {
          _downloadStatus = 'Downloading ${i + 1}/$totalFiles: $fileName';
        });

        // Create ModelInfo for this file
        final modelInfo = ModelInfo(
          id: widget.model.id,
          name: widget.model.modelName,
          description: widget.model.description ?? '',
          fileName: fileName,
          sizeBytes: currentFile.size,
          architecture: widget.model.modelName,
          quantization: file.quantization ?? 'Unknown',
          contextLength: 4096,
          huggingFaceRepo: widget.model.id,
          format: ModelFormat.onnx,
          downloadUrl: currentFile.getDownloadUrl(widget.model.id),
        );

        final success = await downloadService.downloadModel(
          modelInfo: modelInfo,
          onProgress: (progress, status) {
            // Calculate overall progress
            final fileProgress = (i + progress) / totalFiles;
            setState(() {
              _downloadProgress = fileProgress;
              _downloadStatus = 'File ${i + 1}/$totalFiles: $status';
            });
          },
        );

        if (!success) {
          throw Exception('Failed to download $fileName');
        }
      }

      if (!mounted) return;

      // Model info is already saved by ModelDownloadService.selectModel()
      // No need to update AI service here - it will be initialized on next app start

      debugPrint('Model saved to preferences: ${widget.model.id}');

      if (!mounted) return;

      // Show success message with important note
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model ${widget.model.modelName} downloaded!'),
              const SizedBox(height: 4),
              const Text(
                'Note: Local ONNX inference not yet implemented. Using cloud API for now.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

      // Go back to settings
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for selecting quantization
class _QuantizationCard extends StatelessWidget {
  final String quantization;
  final List<HFModelFile> files;
  final void Function(HFModelFile) onDownload;

  const _QuantizationCard({
    required this.quantization,
    required this.files,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort files by size (smallest first)
    final sortedFiles = List<HFModelFile>.from(files)
      ..sort((a, b) => a.size.compareTo(b.size));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quantization,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${sortedFiles.length} file${sortedFiles.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...sortedFiles.map((file) => _FileListTile(
                file: file,
                onDownload: () => onDownload(file),
              )),
        ],
      ),
    );
  }
}

/// List tile for individual file
class _FileListTile extends StatelessWidget {
  final HFModelFile file;
  final VoidCallback onDownload;

  const _FileListTile({
    required this.file,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = file.path.split('/').last;
    final hasRelatedFiles = file.relatedFiles.isNotEmpty;

    return ListTile(
      title: Text(
        fileName,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.formattedSize,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasRelatedFiles) ...[
            const SizedBox(height: 2),
            Text(
              'Includes ${file.relatedFiles.length} data file${file.relatedFiles.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      trailing: FilledButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Download'),
      ),
    );
  }
}
