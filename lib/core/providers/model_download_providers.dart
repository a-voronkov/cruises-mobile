import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/model_info.dart';
import '../services/model_download_service.dart';
import '../services/llama_service_provider.dart';

// Re-export modelDownloadServiceProvider so UI layers can access it from one place.
export '../services/llama_service_provider.dart' show modelDownloadServiceProvider;

/// Provider for fetching the model manifest.
final modelManifestProvider = FutureProvider<ModelManifest?>((ref) async {
  final service = ref.watch(modelDownloadServiceProvider);
  return service.fetchModelManifest();
});

/// Provider for checking which models are downloaded.
final downloadedModelsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(modelDownloadServiceProvider);
  return service.getDownloadedModels();
});

/// State for model download progress.
class ModelDownloadState {
  final bool isDownloading;
  final double progress;
  final String status;
  final String? downloadingModelId;

  const ModelDownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.status = '',
    this.downloadingModelId,
  });

  ModelDownloadState copyWith({
    bool? isDownloading,
    double? progress,
    String? status,
    String? downloadingModelId,
  }) {
    return ModelDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadingModelId: downloadingModelId ?? this.downloadingModelId,
    );
  }
}

/// Notifier for managing model downloads.
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  final ModelDownloadService _service;
  final Ref _ref;

  ModelDownloadNotifier(this._service, this._ref)
      : super(const ModelDownloadState());

  /// Start downloading a specific model.
  Future<bool> downloadModel(ModelInfo model) async {
    if (state.isDownloading) return false;

    state = ModelDownloadState(
      isDownloading: true,
      progress: 0,
      status: 'Preparing download...',
      downloadingModelId: model.id,
    );

    final success = await _service.downloadModel(
      modelInfo: model,
      onProgress: (progress, status) {
        state = state.copyWith(progress: progress, status: status);
      },
    );

    state = ModelDownloadState(
      isDownloading: false,
      progress: success ? 1.0 : 0.0,
      status: success ? 'Download complete!' : 'Download failed',
      downloadingModelId: null,
    );

    // Refresh downloaded models list.
    _ref.invalidate(downloadedModelsProvider);

    return success;
  }

  /// Cancel ongoing download.
  void cancelDownload() {
    _service.cancelDownload();
    state = const ModelDownloadState(
      isDownloading: false,
      progress: 0,
      status: 'Download cancelled',
    );
  }

  /// Delete a specific model.
  Future<bool> deleteModel(ModelInfo model) async {
    final deleted = await _service.deleteModelFile(model.fileName);
    if (deleted) {
      _ref.invalidate(downloadedModelsProvider);
    }
    return deleted;
  }
}

/// Provider for model download state and actions.
final modelDownloadNotifierProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  final service = ref.watch(modelDownloadServiceProvider);
  return ModelDownloadNotifier(service, ref);
});

