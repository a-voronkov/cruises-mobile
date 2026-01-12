import 'package:freezed_annotation/freezed_annotation.dart';

import 'model_info.dart';

part 'model_manifest.freezed.dart';
part 'model_manifest.g.dart';

/// Manifest containing available models for download
@freezed
class ModelManifest with _$ModelManifest {
  const ModelManifest._();

  const factory ModelManifest({
    /// Manifest version for compatibility checking
    required int version,

    /// Base URL for model downloads (can be overridden per model)
    required String baseUrl,

    /// List of available models
    required List<ModelInfo> models,

    /// ID of the recommended model for new users
    String? recommendedModelId,

    /// Last updated timestamp (ISO 8601)
    String? lastUpdated,
  }) = _ModelManifest;

  factory ModelManifest.fromJson(Map<String, dynamic> json) =>
      _$ModelManifestFromJson(json);

  /// Get the recommended model, or the first model if none is recommended
  ModelInfo? get recommendedModel {
    if (models.isEmpty) return null;

    if (recommendedModelId != null) {
      final found = models.where((m) => m.id == recommendedModelId).firstOrNull;
      if (found != null) return found;
    }

    // Fallback to first model marked as recommended
    final recommended = models.where((m) => m.isRecommended).firstOrNull;
    if (recommended != null) return recommended;

    // Fallback to first model
    return models.first;
  }

  /// Get model by ID
  ModelInfo? getModelById(String id) {
    return models.where((m) => m.id == id).firstOrNull;
  }
}

