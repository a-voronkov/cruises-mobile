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
              Icon(Icons.warning_amber, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('No compatible models found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(
                'This model only has GPU or quantized (INT4/INT8) versions, '
                'which are not supported on mobile devices.\n\n'
                'Please choose a model with FP32 or FP16 CPU version.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to model list'),
              ),
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

      // Calculate total size for progress calculation
      final totalBytes = allFiles.fold<int>(0, (sum, f) => sum + f.totalSize);
      var downloadedBytes = 0;

      debugPrint('📦 Total files: $totalFiles, Total size: ${totalBytes / 1024 / 1024} MB');

      setState(() {
        _downloadStatus = 'Downloading $totalFiles file${totalFiles > 1 ? 's' : ''}...';
      });

      // Download all files sequentially
      ModelInfo? mainModelInfo;
      for (int i = 0; i < allFiles.length; i++) {
        final currentFile = allFiles[i];
        final fileName = currentFile.path.split('/').last;
        final fileSize = currentFile.totalSize;

        debugPrint('📥 Starting download ${i + 1}/$totalFiles: $fileName (${fileSize / 1024 / 1024} MB)');

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

        // Save main model info for later initialization
        if (i == 0) {
          mainModelInfo = modelInfo;
        }

        final success = await downloadService.downloadModel(
          modelInfo: modelInfo,
          onProgress: (progress, status) {
            // Calculate overall progress based on bytes downloaded
            final currentFileBytes = (fileSize * progress).toInt();
            final totalDownloaded = downloadedBytes + currentFileBytes;
            final overallProgress = totalBytes > 0 ? totalDownloaded / totalBytes : 0.0;

            setState(() {
              _downloadProgress = overallProgress;
              _downloadStatus = 'File ${i + 1}/$totalFiles: $status (${(overallProgress * 100).toStringAsFixed(1)}% total)';
            });
          },
        );

        if (!success) {
          debugPrint('❌ Failed to download $fileName');
          throw Exception('Failed to download $fileName');
        }

        // Update downloaded bytes counter
        downloadedBytes += fileSize;
        debugPrint('✅ Successfully downloaded ${i + 1}/$totalFiles: $fileName (${downloadedBytes / 1024 / 1024} / ${totalBytes / 1024 / 1024} MB)');

        // Small delay between downloads to let background downloader clean up
        if (i < allFiles.length - 1) {
          debugPrint('⏳ Waiting 1 second before next download...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      debugPrint('🎉 All $totalFiles files downloaded successfully!');

      if (!mounted) return;

      // Now initialize AI service with the main model (after all files are downloaded)
      if (mainModelInfo != null) {
        setState(() {
          _downloadStatus = 'Initializing model...';
          _downloadProgress = 1.0;
        });

        debugPrint('🔧 Initializing AI service with model: ${mainModelInfo.id}');

        // Use selectModel to save and initialize
        await downloadService.selectModel(mainModelInfo);

        // Invalidate AI service state to refresh UI
        ref.invalidate(aiServiceInitializerProvider);

        debugPrint('✅ Model initialized and saved: ${mainModelInfo.id}');
      } else {
        debugPrint('⚠️ No main model info found for initialization');
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model ${widget.model.modelName} downloaded!'),
              const SizedBox(height: 4),
              const Text(
                'Model is ready for local inference',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
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
