import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';
import 'model_download_service.dart';
import '../config/api_config.dart';

/// Provider for AIService singleton
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Provider for ModelDownloadService singleton (shared with settings)
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

/// Provider that initializes AI service on app start
final aiServiceInitializerProvider = FutureProvider<bool>((ref) async {
  final aiService = ref.read(aiServiceProvider);

  if (!ApiConfig.isConfigured) {
    debugPrint('AIService: HF_TOKEN not configured');
    return false;
  }

  debugPrint('AIService: Initializing with API key...');
  final success = await aiService.initialize(
    apiKey: ApiConfig.huggingFaceApiKey,
  );

  if (success) {
    debugPrint('AIService: Initialized successfully');
  } else {
    debugPrint('AIService: Initialization failed');
  }

  return success;
});

/// Provider for AI service state
final aiServiceStateProvider = Provider<AIServiceState>((ref) {
  final initState = ref.watch(aiServiceInitializerProvider);

  return initState.when(
    data: (success) => AIServiceState(
      isReady: success,
      error: success ? null : 'Failed to initialize AI service. Please check your API key.',
    ),
    loading: () => const AIServiceState(isReady: false),
    error: (error, _) => AIServiceState(
      isReady: false,
      error: 'Failed to initialize: $error',
    ),
  );
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

