import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/model_manifest_service.dart';
import '../../domain/entities/model_manifest.dart';

/// Provider for ModelManifestService singleton
final modelManifestServiceProvider = Provider<ModelManifestService>((ref) {
  return ModelManifestService();
});

/// Provider to fetch the model manifest
final modelManifestProvider = FutureProvider<ModelManifest>((ref) async {
  final service = ref.read(modelManifestServiceProvider);
  return service.getManifest();
});

/// Provider for the currently selected model ID
/// Defaults to the recommended model from the manifest
final selectedModelIdProvider = StateProvider<String?>((ref) {
  return null; // Will be set based on manifest or user preference
});

