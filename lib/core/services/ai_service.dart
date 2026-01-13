import 'dart:async';
import 'package:flutter/foundation.dart';
import 'huggingface_inference_service.dart';
import '../constants/app_constants.dart';

/// Service for AI text generation
/// 
/// This service provides a unified interface for text generation,
/// currently using HuggingFace Inference API.
/// 
/// Replaces the old LlamaService which used local llama.cpp inference.
class AIService {
  HuggingFaceInferenceService? _hfService;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _currentModelId;

  /// Check if the service is initialized and ready for inference
  bool get isInitialized => _isInitialized && !_isDisposed;

  /// Get the current model ID
  String? get modelId => _currentModelId;

  /// Initialize the AI service
  /// 
  /// [apiKey] - HuggingFace API key (required)
  /// [modelId] - Model ID to use (optional, uses default from constants)
  /// [onProgress] - Callback for initialization progress (0.0 to 1.0)
  /// 
  /// Returns true if initialization was successful
  Future<bool> initialize({
    required String apiKey,
    String? modelId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (_isInitialized && !_isDisposed) {
        debugPrint('AIService: Already initialized');
        return true;
      }

      // Reset disposed flag if reinitializing
      _isDisposed = false;

      onProgress?.call(0.1);

      // Validate API key
      if (apiKey.isEmpty) {
        debugPrint('AIService: API key is empty');
        return false;
      }

      onProgress?.call(0.3);

      // Initialize HuggingFace service
      _hfService = HuggingFaceInferenceService(apiKey: apiKey);
      _currentModelId = modelId ?? AppConstants.defaultModelId;

      onProgress?.call(0.7);

      debugPrint('AIService: Initialized with model: $_currentModelId');

      _isInitialized = true;
      onProgress?.call(1.0);

      return true;
    } catch (e) {
      debugPrint('AIService: Initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Generate text completion
  /// 
  /// [prompt] - Input prompt
  /// [maxTokens] - Maximum number of tokens to generate
  /// [temperature] - Sampling temperature (0.0 to 1.0)
  /// [topP] - Nucleus sampling parameter
  /// 
  /// Returns generated text
  Future<String> generate({
    required String prompt,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async {
    if (!isInitialized) {
      throw StateError('AIService not initialized');
    }

    if (_hfService == null || _currentModelId == null) {
      throw StateError('HuggingFace service not configured');
    }

    try {
      final result = await _hfService!.generate(
        modelId: _currentModelId!,
        prompt: prompt,
        maxTokens: maxTokens ?? AppConstants.maxTokens,
        temperature: temperature ?? AppConstants.temperature,
        topP: topP ?? AppConstants.topP,
      );

      return result;
    } catch (e) {
      debugPrint('AIService: Generation failed: $e');
      rethrow;
    }
  }

  /// Generate text with streaming response
  /// 
  /// [prompt] - Input prompt
  /// [maxTokens] - Maximum number of tokens to generate
  /// [temperature] - Sampling temperature (0.0 to 1.0)
  /// [topP] - Nucleus sampling parameter
  /// 
  /// Returns a stream of text chunks
  Stream<String> generateStream({
    required String prompt,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async* {
    if (!isInitialized) {
      throw StateError('AIService not initialized');
    }

    if (_hfService == null || _currentModelId == null) {
      throw StateError('HuggingFace service not configured');
    }

    try {
      yield* _hfService!.generateStream(
        modelId: _currentModelId!,
        prompt: prompt,
        maxTokens: maxTokens ?? AppConstants.maxTokens,
        temperature: temperature ?? AppConstants.temperature,
        topP: topP ?? AppConstants.topP,
      );
    } catch (e) {
      debugPrint('AIService: Stream generation failed: $e');
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    if (_isDisposed) return;

    debugPrint('AIService: Disposing...');
    _hfService?.dispose();
    _hfService = null;
    _isInitialized = false;
    _isDisposed = true;
    debugPrint('AIService: Disposed');
  }
}

