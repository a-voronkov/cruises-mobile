import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';

/// Service for local LLM inference using llama.cpp
class LocalInferenceService {
  Llama? _llama;
  bool _isInitialized = false;
  String? _currentModelPath;

  /// Check if the service is initialized and ready for inference
  bool get isInitialized => _isInitialized;

  /// Get the current model path
  String? get modelPath => _currentModelPath;

  /// Initialize the local inference service with a GGUF model
  ///
  /// [modelFileName] - Name of the GGUF model file in the models directory
  /// [onProgress] - Callback for initialization progress (0.0 to 1.0)
  ///
  /// Returns true if initialization was successful
  Future<bool> initialize({
    required String modelFileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (_isInitialized) {
        debugPrint('LocalInferenceService: Already initialized');
        return true;
      }

      onProgress?.call(0.1);

      // Get model path
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/$modelFileName';

      // Check if model file exists
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        debugPrint('LocalInferenceService: Model file not found: $modelPath');
        return false;
      }

      onProgress?.call(0.3);

      debugPrint('LocalInferenceService: Loading model from $modelPath');

      // Set library path (platform-specific)
      if (Platform.isAndroid) {
        Llama.libraryPath = 'libllama.so';
      } else if (Platform.isIOS) {
        Llama.libraryPath = 'libllama.dylib';
      } else if (Platform.isLinux) {
        Llama.libraryPath = 'libllama.so';
      } else if (Platform.isMacOS) {
        Llama.libraryPath = 'libllama.dylib';
      } else if (Platform.isWindows) {
        Llama.libraryPath = 'llama.dll';
      }

      onProgress?.call(0.5);

      // Initialize llama.cpp with model path
      _llama = Llama(modelPath);

      onProgress?.call(0.9);

      _currentModelPath = modelPath;
      _isInitialized = true;

      onProgress?.call(1.0);

      debugPrint('LocalInferenceService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('LocalInferenceService: Initialization failed: $e');
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
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
  }) async {
    if (!_isInitialized || _llama == null) {
      throw StateError('LocalInferenceService not initialized');
    }

    try {
      // Set prompt
      _llama!.setPrompt(prompt);

      // Generate tokens
      final buffer = StringBuffer();
      int tokenCount = 0;

      while (tokenCount < maxTokens) {
        final (token, done) = _llama!.getNext();
        if (done) break;

        buffer.write(token);
        tokenCount++;
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('LocalInferenceService: Generation failed: $e');
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
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
  }) async* {
    if (!_isInitialized || _llama == null) {
      throw StateError('LocalInferenceService not initialized');
    }

    try {
      // Set prompt
      _llama!.setPrompt(prompt);

      // Generate tokens one by one
      int tokenCount = 0;

      while (tokenCount < maxTokens) {
        final (token, done) = _llama!.getNext();
        if (done) break;

        yield token;
        tokenCount++;
      }
    } catch (e) {
      debugPrint('LocalInferenceService: Stream generation failed: $e');
      rethrow;
    }
  }

  /// Dispose the service and free resources
  void dispose() {
    _llama?.dispose();
    _llama = null;
    _isInitialized = false;
    _currentModelPath = null;
    debugPrint('LocalInferenceService: Disposed');
  }
}

