import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_service_provider.dart';
import 'model_download_providers.dart';

/// Global provider to check whether the AI service is ready.
///
/// This is used by [AppInitializer] to decide whether to open the chat or the
/// first-run model setup flow.
///
/// For local ONNX inference, this checks if a model is selected and initialized.
final modelStatusProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('=== Model Status Check ===');

    // Check if model is downloaded
    final modelService = ref.watch(modelDownloadServiceProvider);
    final isModelDownloaded = await modelService.isModelDownloaded();

    debugPrint('Model downloaded: $isModelDownloaded');

    if (!isModelDownloaded) {
      debugPrint('❌ Model not downloaded');
      return false;
    }

    // Wait for AI service initialization
    final initResult = await ref.watch(aiServiceInitializerProvider.future);

    debugPrint('AI Service initialization result: $initResult');

    if (!initResult) {
      debugPrint('❌ AI Service not initialized');
      await bugsnag.notify(
        Exception('AI Service initialization failed'),
        null,
      );
    } else {
      debugPrint('✅ AI Service is ready and model is downloaded');
    }

    return initResult && isModelDownloaded;
  } catch (e, stackTrace) {
    debugPrint('❌ Error checking model status: $e');
    debugPrint('Stack trace: $stackTrace');
    await bugsnag.notify(e, stackTrace);
    return false;
  }
});

