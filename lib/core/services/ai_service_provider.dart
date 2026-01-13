import 'package:bugsnag_flutter/bugsnag_flutter.dart';
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
  try {
    final aiService = ref.read(aiServiceProvider);

    debugPrint('=== AI Service Initialization ===');
    debugPrint('ApiConfig.isConfigured: ${ApiConfig.isConfigured}');
    debugPrint('ApiConfig.huggingFaceApiKey length: ${ApiConfig.huggingFaceApiKey.length}');
    debugPrint('ApiConfig.huggingFaceApiKey (first 10 chars): ${ApiConfig.huggingFaceApiKey.isEmpty ? "EMPTY" : ApiConfig.huggingFaceApiKey.substring(0, ApiConfig.huggingFaceApiKey.length > 10 ? 10 : ApiConfig.huggingFaceApiKey.length)}...');

    if (!ApiConfig.isConfigured) {
      final error = 'HF_TOKEN not configured - API key is empty';
      debugPrint('ERROR: $error');
      await bugsnag.notify(
        Exception(error),
        (event) {
          event.context = 'AI Service Initialization';
          event.addMetadata('config', {
            'isConfigured': ApiConfig.isConfigured,
            'keyLength': ApiConfig.huggingFaceApiKey.length,
          });
        },
      );
      return false;
    }

    debugPrint('Initializing AIService with API key...');
    final success = await aiService.initialize(
      apiKey: ApiConfig.huggingFaceApiKey,
    );

    if (success) {
      debugPrint('✅ AIService initialized successfully');
    } else {
      final error = 'AIService initialization returned false';
      debugPrint('❌ $error');
      await bugsnag.notify(
        Exception(error),
        (event) {
          event.context = 'AI Service Initialization';
          event.addMetadata('config', {
            'isConfigured': ApiConfig.isConfigured,
            'keyLength': ApiConfig.huggingFaceApiKey.length,
          });
        },
      );
    }

    return success;
  } catch (e, stackTrace) {
    debugPrint('❌ Exception during AI service initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    await bugsnag.notify(
      e,
      (event) {
        event.context = 'AI Service Initialization';
        event.addMetadata('config', {
          'isConfigured': ApiConfig.isConfigured,
          'keyLength': ApiConfig.huggingFaceApiKey.length,
        });
      },
    );
    return false;
  }
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

