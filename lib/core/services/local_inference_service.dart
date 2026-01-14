import 'dart:async';
import 'dart:io';
import 'dart:math' show exp;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'tokenizer_service.dart';

/// Service for local LLM inference using ONNX Runtime
///
/// Provides text generation using ONNX models with tokenizer support
class LocalInferenceService {
  OrtSession? _session;
  TokenizerService? _tokenizer;
  bool _isInitialized = false;
  String? _currentModelPath;
  int? _modelSize;

  /// Check if the service is initialized and ready for inference
  bool get isInitialized => _isInitialized;

  /// Get the current model path
  String? get modelPath => _currentModelPath;

  /// Initialize the local inference service with an ONNX model
  ///
  /// [modelFileName] - Name of the ONNX model file in the models directory
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

      onProgress?.call(0.2);

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

      debugPrint('LocalInferenceService: Loading ONNX model from $modelPath');

      // Get model file size
      final fileSize = await modelFile.length();
      _modelSize = fileSize;

      debugPrint('LocalInferenceService: Model file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      onProgress?.call(0.4);

      // Initialize ONNX Runtime
      OrtEnv.instance.init();

      onProgress?.call(0.5);

      // Create session options
      final sessionOptions = OrtSessionOptions();

      // Load model
      debugPrint('LocalInferenceService: Creating ONNX session...');
      _session = OrtSession.fromFile(modelFile, sessionOptions);

      onProgress?.call(0.7);

      // Initialize tokenizer
      final modelDir = modelFile.parent.path;
      debugPrint('LocalInferenceService: Loading tokenizer from $modelDir');

      _tokenizer = TokenizerService();
      final tokenizerLoaded = await _tokenizer!.initialize(modelDir);

      if (!tokenizerLoaded) {
        debugPrint('LocalInferenceService: Warning - tokenizer not loaded, using fallback');
      }

      onProgress?.call(0.9);

      _currentModelPath = modelPath;
      _isInitialized = true;

      onProgress?.call(1.0);

      debugPrint('LocalInferenceService: ONNX model initialized successfully');
      debugPrint('LocalInferenceService: Tokenizer vocab size: ${_tokenizer?.vocabSize ?? 0}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('LocalInferenceService: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
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
    if (!_isInitialized || _session == null) {
      throw StateError('LocalInferenceService not initialized');
    }

    try {
      debugPrint('LocalInferenceService: Generating text for prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');

      // If tokenizer is not available, return informative message
      if (_tokenizer == null || !_tokenizer!.isInitialized) {
        final modelSizeMB = _modelSize != null ? (_modelSize! / 1024 / 1024).toStringAsFixed(2) : 'unknown';

        return '✅ ONNX Model Loaded!\n\n'
               '📁 Model: $_currentModelPath\n'
               '💾 Size: $modelSizeMB MB\n\n'
               '📝 Your prompt:\n"$prompt"\n\n'
               '⚠️ Tokenizer files not found. Please ensure the model includes:\n'
               '• tokenizer.json or vocab.json\n'
               '• tokenizer_config.json\n'
               '• config.json\n\n'
               'These files are required for text generation.';
      }

      // Encode prompt to token IDs
      final inputIds = _tokenizer!.encode(prompt);
      debugPrint('LocalInferenceService: Encoded to ${inputIds.length} tokens');

      // Prepare input tensor
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        [inputIds],
        [1, inputIds.length],
      );

      // Run inference
      final inputs = {'input_ids': inputTensor};
      final outputs = _session!.run(OrtRunOptions(), inputs);

      // Get output logits
      final outputTensor = outputs[0];
      final logits = outputTensor?.value as List<List<List<double>>>?;

      if (logits == null || logits.isEmpty) {
        throw Exception('No output from model');
      }

      // Get last token logits and sample next token
      final lastLogits = logits[0].last;
      final nextTokenId = _sampleToken(lastLogits, temperature, topP);

      // Decode output
      final outputIds = [...inputIds, nextTokenId];
      final generatedText = _tokenizer!.decode(outputIds);

      debugPrint('LocalInferenceService: Generated ${outputIds.length} tokens');

      // Clean up
      inputTensor.release();
      outputTensor?.release();

      return generatedText;
    } catch (e, stackTrace) {
      debugPrint('LocalInferenceService: Generation failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Sample next token from logits
  int _sampleToken(List<double> logits, double temperature, double topP) {
    // Apply temperature
    final scaledLogits = logits.map((l) => l / temperature).toList();

    // Softmax
    final maxLogit = scaledLogits.reduce((a, b) => a > b ? a : b);
    final expLogits = scaledLogits.map((l) => exp(l - maxLogit)).toList();
    final sumExp = expLogits.reduce((a, b) => a + b);
    final probs = expLogits.map((e) => e / sumExp).toList();

    // Greedy sampling (take argmax)
    // TODO: Implement top-p sampling
    var maxProb = 0.0;
    var maxIndex = 0;
    for (var i = 0; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  /// Generate text with streaming response
  ///
  /// Note: This is a placeholder implementation.
  /// For production, implement proper token-by-token generation.
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
    if (!_isInitialized) {
      throw StateError('LocalInferenceService not initialized');
    }

    // Simulate streaming by yielding the full response in chunks
    final response = await generate(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
    );

    // Simulate streaming by splitting into words
    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      yield words[i] + (i < words.length - 1 ? ' ' : '');
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Dispose the service and free resources
  void dispose() {
    _session?.release();
    _session = null;
    _tokenizer?.dispose();
    _tokenizer = null;
    _isInitialized = false;
    _currentModelPath = null;
    _modelSize = null;
    debugPrint('LocalInferenceService: Disposed');
  }
}

