import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_service_provider.dart' show modelDownloadServiceProvider;

/// Global provider to check whether the currently selected model is downloaded.
///
/// This is used by [AppInitializer] to decide whether to open the chat or the
/// first-run model setup flow.
final modelStatusProvider = FutureProvider<bool>((ref) async {
  final downloadService = ref.watch(modelDownloadServiceProvider);
  return downloadService.isModelDownloaded();
});

