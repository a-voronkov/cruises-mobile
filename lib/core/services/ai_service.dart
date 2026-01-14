import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_inference_service.dart';
import '../constants/app_constants.dart';

/// Service for AI text generation using local ONNX inference
///
/// This service provides a unified interface for text generation
/// using locally downloaded ONNX models.
class AIService {
  LocalInferenceService? _localService;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _currentModelId;
  String? _currentModelFileName;

  /// Check if the service is initialized and ready for inference
  bool get isInitialized => _isInitialized && !_isDisposed;

  /// Get the current model ID
  String? get modelId => _currentModelId;

  /// Get the current model file name
  String? get modelFileName => _currentModelFileName;

  /// Set the model ID and file name
  ///
  /// This saves the model information to preferences
  Future<void> _saveModelInfo(String modelId, String modelFileName) async {
    _currentModelId = modelId;
    _currentModelFileName = modelFileName;

    // Save to preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_model_id', modelId);
      await prefs.setString('selected_model_file', modelFileName);
    } catch (e) {
      debugPrint('AIService: Failed to save model info: $e');
    }

    debugPrint('AIService: Model info saved: $modelId ($modelFileName)');
  }

  /// Initialize the AI service with a local ONNX model
  ///
  /// [modelId] - Model ID (e.g., "onnx-community/Llama-3.2-1B-Instruct-ONNX")
  /// [modelFileName] - Name of the ONNX model file in the models directory
  /// [onProgress] - Callback for initialization progress (0.0 to 1.0)
  ///
  /// Returns true if initialization was successful
  Future<bool> initialize({
    required String modelId,
    required String modelFileName,
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

      debugPrint('AIService: Initializing with model: $modelId ($modelFileName)');

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

      await _saveModelInfo(modelId, modelFileName);
      _isInitialized = true;

      debugPrint('AIService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('AIService: Initialization failed: $e');
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
    if (!isInitialized || _localService == null) {
      throw StateError('AIService not initialized');
    }

    try {
      return await _localService!.generate(
        prompt: prompt,
        maxTokens: maxTokens ?? AppConstants.maxTokens,
        temperature: temperature ?? AppConstants.temperature,
        topP: topP ?? AppConstants.topP,
      );
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
    if (!isInitialized || _localService == null) {
      throw StateError('AIService not initialized');
    }

    try {
      // Convert messages to prompt format
      final prompt = _formatMessagesToPrompt(messages);

      yield* _localService!.generateStream(
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
    _localService?.dispose();
    _localService = null;
    _isInitialized = false;
    _isDisposed = true;
    debugPrint('AIService: Disposed');
  }
}

