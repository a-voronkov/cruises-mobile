import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'model_download_service.dart';

/// Provider for ModelDownloadService singleton
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

/// Provider to check if model is downloaded
final isModelDownloadedProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(modelDownloadServiceProvider);
  return service.isModelDownloaded();
});

/// State for model download progress
class ModelDownloadState {
  final bool isDownloading;
  final double progress;
  final String statusMessage;
  final bool isComplete;
  final String? error;

  const ModelDownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.statusMessage = '',
    this.isComplete = false,
    this.error,
  });

  ModelDownloadState copyWith({
    bool? isDownloading,
    double? progress,
    String? statusMessage,
    bool? isComplete,
    String? error,
  }) {
    return ModelDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      isComplete: isComplete ?? this.isComplete,
      error: error,
    );
  }
}

/// Notifier for managing model download
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  final ModelDownloadService _service;

  ModelDownloadNotifier(this._service) : super(const ModelDownloadState());

  /// Start downloading the model
  Future<bool> startDownload() async {
    if (state.isDownloading) return false;

    state = state.copyWith(
      isDownloading: true,
      progress: 0.0,
      statusMessage: 'Preparing download...',
      isComplete: false,
      error: null,
    );

    final success = await _service.downloadModel(
      onProgress: (progress, status) {
        state = state.copyWith(
          progress: progress,
          statusMessage: status,
        );
      },
    );

    if (success) {
      state = state.copyWith(
        isDownloading: false,
        isComplete: true,
        progress: 1.0,
        statusMessage: 'Download complete!',
      );
    } else {
      state = state.copyWith(
        isDownloading: false,
        isComplete: false,
        error: state.statusMessage,
      );
    }

    return success;
  }

  /// Cancel the current download
  void cancelDownload() {
    _service.cancelDownload();
    state = state.copyWith(
      isDownloading: false,
      statusMessage: 'Download cancelled',
    );
  }

  /// Reset the state
  void reset() {
    state = const ModelDownloadState();
  }
}

/// Provider for model download state
final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  final service = ref.read(modelDownloadServiceProvider);
  return ModelDownloadNotifier(service);
});

