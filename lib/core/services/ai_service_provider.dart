import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'model_download_service.dart';
import 'hive_service.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';
import '../models/model_info.dart';

/// Provider for AIService singleton
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Provider for ModelDownloadService singleton (shared with settings)
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  final aiService = ref.read(aiServiceProvider);
  return ModelDownloadService(aiService: aiService);
});

/// Provider that initializes AI service on app start
final aiServiceInitializerProvider = FutureProvider<bool>((ref) async {
  try {
    final aiService = ref.read(aiServiceProvider);

    debugPrint('=== AI Service Initialization ===');
    debugPrint('ApiConfig.isConfigured: ${ApiConfig.isConfigured}');
    debugPrint('ApiConfig.huggingFaceApiKey length: ${ApiConfig.huggingFaceApiKey.length}');
    final firstChars = ApiConfig.huggingFaceApiKey.isEmpty
        ? "EMPTY"
        : ApiConfig.huggingFaceApiKey.substring(0, ApiConfig.huggingFaceApiKey.length > 10 ? 10 : ApiConfig.huggingFaceApiKey.length);
    debugPrint('ApiConfig.huggingFaceApiKey (first 10 chars): $firstChars...');

    if (!ApiConfig.isConfigured) {
      const error = 'HF_TOKEN not configured - API key is empty';
      debugPrint('ERROR: $error');
      await bugsnag.notify(Exception(error), null);
      return false;
    }

    debugPrint('Initializing AIService with API key...');
    final success = await aiService.initialize(
      apiKey: ApiConfig.huggingFaceApiKey,
    );

    if (!success) {
      const error = 'AIService initialization returned false';
      debugPrint('❌ $error');
      await bugsnag.notify(Exception(error), null);
      return false;
    }

    debugPrint('✅ AIService initialized successfully (cloud mode)');

    // Check if there's a saved ONNX model to switch to
    try {
      final modelJson = HiveService.settingsBox.get(AppConstants.modelStorageKey);
      if (modelJson != null) {
        final model = ModelInfo.fromJson(Map<String, dynamic>.from(modelJson as Map));
        debugPrint('Found saved model: ${model.huggingFaceRepo} (${model.format.name})');

        if (model.format == ModelFormat.onnx && model.huggingFaceRepo != null) {
          debugPrint('Switching to saved ONNX model...');
          final switchSuccess = await aiService.switchToModel(
            modelId: model.huggingFaceRepo!,
            modelFileName: model.fileName,
          );

          if (switchSuccess) {
            debugPrint('✅ Switched to ONNX model: ${model.huggingFaceRepo}');
          } else {
            debugPrint('⚠️ Failed to switch to ONNX model, staying in cloud mode');
          }
        } else {
          debugPrint('Saved model is not ONNX, staying in cloud mode');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error checking saved model: $e');
      // Continue with cloud mode
    }

    return true;
  } catch (e, stackTrace) {
    debugPrint('❌ Exception during AI service initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    await bugsnag.notify(e, stackTrace);
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

