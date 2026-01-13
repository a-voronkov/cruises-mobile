import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_service_provider.dart';

/// Global provider to check whether the AI service is ready.
///
/// This is used by [AppInitializer] to decide whether to open the chat or the
/// first-run model setup flow.
///
/// For cloud-based AI, this checks if the service is initialized with API key.
final modelStatusProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('=== Model Status Check ===');

    // Wait for AI service initialization
    final initResult = await ref.watch(aiServiceInitializerProvider.future);

    debugPrint('AI Service initialization result: $initResult');

    if (!initResult) {
      debugPrint('❌ AI Service not initialized');
      await bugsnag.notify(
        Exception('AI Service initialization failed'),
        stackTrace,
      );
    } else {
      debugPrint('✅ AI Service is ready');
    }

    return initResult;
  } catch (e, stackTrace) {
    debugPrint('❌ Error checking model status: $e');
    debugPrint('Stack trace: $stackTrace');
    await bugsnag.notify(e, stackTrace);
    return false;
  }
});

