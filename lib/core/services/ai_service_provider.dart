import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';
import 'model_download_service.dart';
import 'hive_service.dart';
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

    // Check if there's a saved ONNX model
    final modelJson = HiveService.settingsBox.get(AppConstants.modelStorageKey);
    if (modelJson == null) {
      debugPrint('⚠️ No model selected - user needs to select a model first');
      return false;
    }

    final model = ModelInfo.fromJson(Map<String, dynamic>.from(modelJson as Map));
    debugPrint('Found saved model: ${model.huggingFaceRepo} (${model.format.name})');

    if (model.format != ModelFormat.onnx) {
      debugPrint('❌ Saved model is not ONNX format');
      return false;
    }

    if (model.huggingFaceRepo == null) {
      debugPrint('❌ Model has no HuggingFace repo ID');
      return false;
    }

    debugPrint('Initializing AIService with ONNX model: ${model.huggingFaceRepo}');
    final success = await aiService.initialize(
      modelId: model.huggingFaceRepo!,
      modelFileName: model.fileName,
      onProgress: (progress) {
        debugPrint('Initialization progress: ${(progress * 100).toStringAsFixed(0)}%');
      },
    );

    if (success) {
      debugPrint('✅ AIService initialized successfully');
    } else {
      const error = 'AIService initialization returned false';
      debugPrint('❌ $error');
      await bugsnag.notify(Exception(error), null);
    }

    return success;
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
    this.isReady = false,
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

