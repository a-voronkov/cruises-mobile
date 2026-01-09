import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'llama_service.dart';

/// Provider for LlamaService singleton
final llamaServiceProvider = Provider<LlamaService>((ref) {
  final service = LlamaService();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for model initialization state
final modelInitializationProvider = StateNotifierProvider<ModelInitializationNotifier, ModelInitializationState>((ref) {
  return ModelInitializationNotifier(ref.read(llamaServiceProvider));
});

/// State for model initialization
class ModelInitializationState {
  final bool isInitialized;
  final bool isLoading;
  final double progress;
  final String? error;

  const ModelInitializationState({
    this.isInitialized = false,
    this.isLoading = false,
    this.progress = 0.0,
    this.error,
  });

  ModelInitializationState copyWith({
    bool? isInitialized,
    bool? isLoading,
    double? progress,
    String? error,
  }) {
    return ModelInitializationState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing model initialization
class ModelInitializationNotifier extends StateNotifier<ModelInitializationState> {
  final LlamaService _llamaService;

  ModelInitializationNotifier(this._llamaService) : super(const ModelInitializationState());

  /// Initialize the model
  Future<void> initialize() async {
    if (state.isInitialized || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null, progress: 0.0);

    try {
      final success = await _llamaService.initialize(
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      if (success) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          progress: 1.0,
        );
      } else {
        state = state.copyWith(
          isInitialized: false,
          isLoading: false,
          error: 'Failed to initialize model. Please check if the model file exists.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        isLoading: false,
        error: 'Error initializing model: $e',
      );
    }
  }

  /// Reset initialization state
  void reset() {
    state = const ModelInitializationState();
  }
}

