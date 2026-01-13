import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Information about an AI model available for download
@freezed
class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    required String id,
    required String name,
    required String description,
    required String fileName,
    required int sizeBytes,
    required String architecture,
    required String quantization,
    required int contextLength,
    @Default(false) bool recommended,
    @Default([]) List<String> tags,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) => _$ModelInfoFromJson(json);
}

/// Model manifest containing list of available models
@freezed
class ModelManifest with _$ModelManifest {
  const factory ModelManifest({
    required String version,
    required String lastUpdated,
    required List<ModelInfo> models,
  }) = _ModelManifest;

  factory ModelManifest.fromJson(Map<String, dynamic> json) => _$ModelManifestFromJson(json);
}

/// Extension methods for ModelInfo
extension ModelInfoExtension on ModelInfo {
  /// Format size in human readable format (MB/GB)
  String get formattedSize {
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }

  /// Check if this model is compact (under 1GB)
  bool get isCompact => sizeBytes < 1024 * 1024 * 1024;
}

