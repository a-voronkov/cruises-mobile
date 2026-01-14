import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'huggingface_inference_service.dart';
import 'local_inference_service.dart';
import '../constants/app_constants.dart';

enum InferenceMode {
  cloud, // HuggingFace Inference API
  local, // Local llama.cpp inference
}

/// Service for AI text generation
///
/// This service provides a unified interface for text generation,
/// supporting both cloud (HuggingFace) and local (llama.cpp) inference.
class AIService {
  HuggingFaceInferenceService? _hfService;
  LocalInferenceService? _localService;
  InferenceMode _mode = InferenceMode.cloud;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _currentModelId;

  /// Check if the service is initialized and ready for inference
  bool get isInitialized => _isInitialized && !_isDisposed;

  /// Get the current model ID
  String? get modelId => _currentModelId;

  /// Get the current inference mode
  InferenceMode get mode => _mode;

  /// Check if using local inference
  bool get isLocal => _mode == InferenceMode.local;

  /// Set the model ID to use for generation
  ///
  /// This allows changing the model without reinitializing the service
  void setModelId(String modelId) {
    _currentModelId = modelId;
    debugPrint('AIService: Model changed to: $modelId');
  }

  /// Initialize the AI service for cloud inference
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
      if (_isInitialized && !_isDisposed && _mode == InferenceMode.cloud) {
        debugPrint('AIService: Already initialized (cloud mode)');
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
      _mode = InferenceMode.cloud;

      // Load saved model ID or use provided/default
      if (modelId != null) {
        _currentModelId = modelId;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _currentModelId = prefs.getString('selected_model_id') ?? AppConstants.defaultModelId;
      }

      onProgress?.call(0.7);

      debugPrint('AIService: Initialized with cloud model: $_currentModelId');

      _isInitialized = true;
      onProgress?.call(1.0);

      return true;
    } catch (e) {
      debugPrint('AIService: Cloud initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Initialize the AI service for local inference
  ///
  /// [modelFileName] - Name of the GGUF model file in the models directory
  /// [onProgress] - Callback for initialization progress (0.0 to 1.0)
  ///
  /// Returns true if initialization was successful
  Future<bool> initializeLocal({
    required String modelFileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (_isInitialized && !_isDisposed && _mode == InferenceMode.local) {
        debugPrint('AIService: Already initialized (local mode)');
        return true;
      }

      // Reset disposed flag if reinitializing
      _isDisposed = false;

      onProgress?.call(0.1);

      // Initialize local service
      _localService = LocalInferenceService();
      final success = await _localService!.initialize(
        modelFileName: modelFileName,
        onProgress: onProgress,
      );

      if (!success) {
        debugPrint('AIService: Local service initialization failed');
        _localService = null;
        return false;
      }

      _mode = InferenceMode.local;
      _currentModelId = modelFileName;
      _isInitialized = true;

      debugPrint('AIService: Initialized with local model: $modelFileName');
      return true;
    } catch (e) {
      debugPrint('AIService: Local initialization failed: $e');
      _isInitialized = false;
      _localService = null;
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

    try {
      if (_mode == InferenceMode.local) {
        if (_localService == null) {
          throw StateError('Local service not configured');
        }
        return await _localService!.generate(
          prompt: prompt,
          maxTokens: maxTokens ?? AppConstants.maxTokens,
          temperature: temperature ?? AppConstants.temperature,
          topP: topP ?? AppConstants.topP,
        );
      } else {
        if (_hfService == null || _currentModelId == null) {
          throw StateError('HuggingFace service not configured');
        }
        return await _hfService!.generate(
          modelId: _currentModelId!,
          prompt: prompt,
          maxTokens: maxTokens ?? AppConstants.maxTokens,
          temperature: temperature ?? AppConstants.temperature,
          topP: topP ?? AppConstants.topP,
        );
      }
    } catch (e) {
      debugPrint('AIService: Generation failed: $e');
      rethrow;
    }
  }

  /// Generate text with streaming response
  ///
  /// [messages] - List of conversation messages in format: [{'role': 'user', 'content': '...'}]
  /// [maxTokens] - Maximum number of tokens to generate
  /// [temperature] - Sampling temperature (0.0 to 1.0)
  /// [topP] - Nucleus sampling parameter
  ///
  /// Returns a stream of text chunks
  Stream<String> generateStream({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async* {
    if (!isInitialized) {
      throw StateError('AIService not initialized');
    }

    try {
      // Convert messages to prompt format
      final prompt = _formatMessagesToPrompt(messages);

      if (_mode == InferenceMode.local) {
        if (_localService == null) {
          throw StateError('Local service not configured');
        }
        yield* _localService!.generateStream(
          prompt: prompt,
          maxTokens: maxTokens ?? AppConstants.maxTokens,
          temperature: temperature ?? AppConstants.temperature,
          topP: topP ?? AppConstants.topP,
        );
      } else {
        if (_hfService == null || _currentModelId == null) {
          throw StateError('HuggingFace service not configured');
        }
        yield* _hfService!.generateStream(
          modelId: _currentModelId!,
          prompt: prompt,
          maxTokens: maxTokens ?? AppConstants.maxTokens,
          temperature: temperature ?? AppConstants.temperature,
          topP: topP ?? AppConstants.topP,
        );
      }
    } catch (e) {
      debugPrint('AIService: Stream generation failed: $e');
      rethrow;
    }
  }

  /// Convert messages to prompt format
  String _formatMessagesToPrompt(List<Map<String, String>> messages) {
    final buffer = StringBuffer();

    for (final message in messages) {
      final role = message['role'] ?? 'user';
      final content = message['content'] ?? '';

      if (role == 'system') {
        buffer.write('System: $content\n\n');
      } else if (role == 'user') {
        buffer.write('User: $content\n\n');
      } else if (role == 'assistant') {
        buffer.write('Assistant: $content\n\n');
      }
    }

    buffer.write('Assistant:');
    return buffer.toString();
  }

  /// Dispose of resources
  void dispose() {
    if (_isDisposed) return;

    debugPrint('AIService: Disposing...');
    _hfService?.dispose();
    _hfService = null;
    _localService?.dispose();
    _localService = null;
    _isInitialized = false;
    _isDisposed = true;
    debugPrint('AIService: Disposed');
  }
}

