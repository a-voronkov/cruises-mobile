import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Quantization type for GGUF models
enum QuantizationType {
  @JsonValue('q4_k_m')
  q4KM,
  @JsonValue('q5_k_m')
  q5KM,
  @JsonValue('q6_k')
  q6K,
  @JsonValue('q8_0')
  q80,
  @JsonValue('f16')
  f16,
}

/// Model capability tags
enum ModelCapability {
  @JsonValue('chat')
  chat,
  @JsonValue('multilingual')
  multilingual,
  @JsonValue('coding')
  coding,
  @JsonValue('reasoning')
  reasoning,
  @JsonValue('vision')
  vision,
}

/// Information about a downloadable LLM model
@freezed
abstract class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    /// Unique identifier for the model
    required String id,

    /// Human-readable display name
    required String name,

    /// Model version (e.g., "1.2B")
    required String version,

    /// Description of the model
    required String description,

    /// File name for the GGUF model
    required String fileName,

    /// Direct download URL
    required String downloadUrl,

    /// File size in bytes
    required int sizeBytes,

    /// Quantization type
    required QuantizationType quantization,

    /// Model capabilities
    @Default([]) List<ModelCapability> capabilities,

    /// Context window size in tokens
    @Default(4096) int contextSize,

    /// Whether this is the recommended model
    @Default(false) bool isRecommended,

    /// Minimum RAM required in MB
    @Default(512) int minRamMb,

    /// Languages supported (ISO codes)
    @Default(['en']) List<String> languages,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}

