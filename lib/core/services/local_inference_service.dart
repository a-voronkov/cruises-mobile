import 'dart:async';
import 'dart:io';
import 'dart:math' show exp;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
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
      OnnxRuntime.init();

      onProgress?.call(0.5);

      // Create session options
      final sessionOptions = OrtSessionOptions();

      // Load model
      debugPrint('LocalInferenceService: Creating ONNX session...');
      try {
        _session = OrtSession.fromFile(modelPath, sessionOptions);
      } catch (e) {
        final errorMsg = e.toString();

        // Check for IR version mismatch
        if (errorMsg.contains('Unsupported model IR version')) {
          debugPrint('❌ Model uses newer ONNX IR version than supported');
          debugPrint('   Current ONNX Runtime supports IR version up to 9');
          debugPrint('   This model requires IR version 10 or higher');
          debugPrint('   Please use a model exported with ONNX opset 13 or lower');
          throw Exception(
            'Model incompatible: This model uses ONNX IR version 10, but the app only supports up to version 9. '
            'Please choose a different model or use a model exported with ONNX opset 13 or lower.'
          );
        }

        // Re-throw other errors
        rethrow;
      }

      // Check model inputs to detect encoder-decoder models
      final inputNames = _session!.inputNames;
      debugPrint('LocalInferenceService: Model inputs: $inputNames');

      // Check if this is an encoder-decoder model (like T5, BART)
      if (inputNames.contains('encoder_hidden_states') ||
          modelPath.contains('decoder_model') ||
          modelPath.contains('encoder_model')) {
        debugPrint('❌ Encoder-decoder models (T5, BART, etc.) are not supported');
        debugPrint('   Please use decoder-only models (GPT, Llama, Phi, etc.)');
        debugPrint('   Or use HuggingFace cloud API instead');
        throw Exception(
          'Encoder-decoder models are not supported. '
          'This model requires both encoder and decoder components. '
          'Please use decoder-only models (GPT-like) or HuggingFace cloud API.'
        );
      }

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

      // Prepare input tensor (convert to Int64List)
      final inputData = Int64List.fromList(inputIds);
      final inputTensor = OrtValue.createTensorWithDataList(
        inputData,
        [1, inputIds.length],
      );

      // Prepare position_ids (0, 1, 2, ..., length-1)
      final positionIds = List<int>.generate(inputIds.length, (i) => i);
      final positionData = Int64List.fromList(positionIds);
      final positionTensor = OrtValue.createTensorWithDataList(
        positionData,
        [1, inputIds.length],
      );

      // Prepare attention_mask (all 1s)
      final attentionMask = List<int>.filled(inputIds.length, 1);
      final attentionData = Int64List.fromList(attentionMask);
      final attentionTensor = OrtValue.createTensorWithDataList(
        attentionData,
        [1, inputIds.length],
      );

      // Check what inputs the model expects
      final inputNames = _session!.inputNames;
      debugPrint('LocalInferenceService: Model expects inputs: $inputNames');

      // Build inputs map based on what model expects
      final inputs = <String, OrtValue>{
        'input_ids': inputTensor,
      };

      if (inputNames.contains('position_ids')) {
        inputs['position_ids'] = positionTensor;
      }

      if (inputNames.contains('attention_mask')) {
        inputs['attention_mask'] = attentionTensor;
      }
      final outputs = _session!.run(OrtRunOptions(), inputs);

      // Get output logits
      final outputTensor = outputs[0];
      if (outputTensor == null) {
        throw Exception('No output from model');
      }

      final logits = outputTensor.value as List<List<List<double>>>?;

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
      if (inputs.containsKey('position_ids')) {
        inputs['position_ids']?.release();
      }
      if (inputs.containsKey('attention_mask')) {
        inputs['attention_mask']?.release();
      }
      outputTensor.release();

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

