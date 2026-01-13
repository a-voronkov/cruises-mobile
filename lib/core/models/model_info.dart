/// Model format type
enum ModelFormat {
  onnx,
  gguf; // Legacy format, kept for backwards compatibility

  String get displayName {
    switch (this) {
      case ModelFormat.onnx:
        return 'ONNX';
      case ModelFormat.gguf:
        return 'GGUF';
    }
  }
}

/// Information about an AI model available for download.
///
/// NOTE: We intentionally avoid code generation (freezed/json_serializable)
/// here to keep `flutter analyze` green without requiring build_runner.
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final String fileName;
  final int sizeBytes;
  final String architecture;
  final String quantization;
  final int contextLength;
  final bool recommended;
  final List<String> tags;

  /// HuggingFace repository ID (e.g., "LiquidAI/LFM2.5-1.2B-Instruct-ONNX")
  final String? huggingFaceRepo;

  /// Model format (ONNX or GGUF)
  final ModelFormat format;

  /// Direct download URL (optional, if not using HuggingFace)
  final String? downloadUrl;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.fileName,
    required this.sizeBytes,
    required this.architecture,
    required this.quantization,
    required this.contextLength,
    this.recommended = false,
    this.tags = const [],
    this.huggingFaceRepo,
    this.format = ModelFormat.onnx,
    this.downloadUrl,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      fileName: json['fileName'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      architecture: json['architecture'] as String,
      quantization: json['quantization'] as String,
      contextLength: (json['contextLength'] as num).toInt(),
      recommended: json['recommended'] as bool? ?? false,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
      huggingFaceRepo: json['huggingFaceRepo'] as String?,
      format: json['format'] != null
          ? ModelFormat.values.firstWhere(
              (e) => e.name == json['format'],
              orElse: () => ModelFormat.onnx,
            )
          : ModelFormat.onnx,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'architecture': architecture,
      'quantization': quantization,
      'contextLength': contextLength,
      'recommended': recommended,
      'tags': tags,
      if (huggingFaceRepo != null) 'huggingFaceRepo': huggingFaceRepo,
      'format': format.name,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
    };
  }

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

/// Model manifest containing list of available models
class ModelManifest {
  final String version;
  final String lastUpdated;
  final List<ModelInfo> models;

  const ModelManifest({
    required this.version,
    required this.lastUpdated,
    required this.models,
  });

  factory ModelManifest.fromJson(Map<String, dynamic> json) {
    return ModelManifest(
      version: json['version'] as String,
      lastUpdated: json['lastUpdated'] as String,
      models: (json['models'] as List)
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated,
      'models': models.map((e) => e.toJson()).toList(),
    };
  }
}

