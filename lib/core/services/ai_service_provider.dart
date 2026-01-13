import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';
import 'model_download_service.dart';

/// Provider for AIService singleton
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Provider for ModelDownloadService singleton (shared with settings)
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

/// Provider for AI service state
final aiServiceStateProvider = StateNotifierProvider<AIServiceStateNotifier, AIServiceState>((ref) {
  final aiService = ref.read(aiServiceProvider);
  return AIServiceStateNotifier(aiService);
});

/// State for AI service
class AIServiceState {
  final bool isReady;
  final String? error;

  const AIServiceState({
    this.isReady = true, // Cloud-based service is always ready
    this.error,
  });

  AIServiceState copyWith({
    bool? isReady,
    String? error,
  }) {
    return AIServiceState(
      isReady: isReady ?? this.isReady,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing AI service state
class AIServiceStateNotifier extends StateNotifier<AIServiceState> {
  final AIService _aiService;

  AIServiceStateNotifier(this._aiService)
      : super(const AIServiceState());

  /// Check if service is ready
  bool isReady() {
    return state.isReady;
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

