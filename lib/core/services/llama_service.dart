import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Service for managing llama.cpp model lifecycle and inference
/// 
/// This service handles:
/// - Model loading and initialization
/// - Inference with streaming support
/// - Resource management and cleanup
class LlamaService {
  LlamaParent? _llamaParent;
  bool _isInitialized = false;
  String? _modelPath;

  /// Check if the service is initialized and ready for inference
  bool get isInitialized => _isInitialized;

  /// Get the current model path
  String? get modelPath => _modelPath;

  /// Initialize the llama.cpp model
  /// 
  /// [modelFileName] - Name of the GGUF model file (optional, uses default from constants)
  /// [onProgress] - Callback for initialization progress (0.0 to 1.0)
  /// 
  /// Returns true if initialization was successful
  Future<bool> initialize({
    String? modelFileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (_isInitialized) {
        print('LlamaService: Already initialized');
        return true;
      }

      onProgress?.call(0.1);

      // Get model path
      final fileName = modelFileName ?? AppConstants.modelFileName;
      _modelPath = await _getModelPath(fileName);

      if (_modelPath == null || !await File(_modelPath!).exists()) {
        print('LlamaService: Model file not found at $_modelPath');
        return false;
      }

      onProgress?.call(0.3);

      // Set library path based on platform
      final libraryPath = await _getLibraryPath();
      if (libraryPath != null) {
        Llama.libraryPath = libraryPath;
      }

      onProgress?.call(0.5);

      // Create load command with LFM2.5 optimized parameters
      final loadCommand = LlamaLoad(
        path: _modelPath!,
        modelParams: ModelParams(
          nGpuLayers: 0, // CPU inference for now, can enable GPU later
          mainGpu: 0,
          splitMode: 0,
          vocabOnly: false,
          useMmap: true,
          useMlock: false,
        ),
        contextParams: ContextParams(
          nCtx: AppConstants.contextLength,
          nBatch: 512,
          nThreads: AppConstants.numThreads,
          nThreadsBatch: AppConstants.numThreads,
          ropeFreqBase: 0.0,
          ropeFreqScale: 0.0,
          yarnExtFactor: -1.0,
          yarnAttnFactor: 1.0,
          yarnBetaFast: 32.0,
          yarnBetaSlow: 1.0,
          yarnOrigCtx: 0,
          defragmentationThreshold: -1.0,
          embeddings: false,
          offloadKqv: true,
          flashAttention: false,
        ),
        samplingParams: SamplerParams(
          temperature: AppConstants.temperature,
          topK: AppConstants.topK,
          topP: AppConstants.topP,
          minP: 0.05,
          typicalP: 1.0,
          penaltyLastN: 64,
          penaltyRepeat: AppConstants.repetitionPenalty,
          penaltyFreq: 0.0,
          penaltyPresent: 0.0,
          mirostat: 0,
          mirostatTau: 5.0,
          mirostatEta: 0.1,
          penalizeNl: false,
          seed: 0xFFFFFFFF,
          nPredict: AppConstants.maxTokens,
        ),
        format: ChatMLFormat(), // LFM2.5 uses ChatML-like format
      );

      onProgress?.call(0.7);

      // Initialize LlamaParent (runs in isolate for non-blocking)
      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init();

      onProgress?.call(1.0);

      _isInitialized = true;
      print('LlamaService: Initialized successfully with model: $_modelPath');
      return true;
    } catch (e, stackTrace) {
      print('LlamaService: Initialization failed: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// Generate text from a prompt with streaming support
  /// 
  /// [prompt] - The input prompt (should be pre-formatted with ChatTemplate)
  /// 
  /// Returns a stream of generated tokens
  Stream<String> generateStream(String prompt) {
    if (!_isInitialized || _llamaParent == null) {
      throw StateError('LlamaService not initialized. Call initialize() first.');
    }

    // Send prompt to the isolate
    _llamaParent!.sendPrompt(prompt);

    // Return the stream of responses
    return _llamaParent!.stream;
  }

  /// Generate text from a prompt (non-streaming)
  /// 
  /// [prompt] - The input prompt (should be pre-formatted with ChatTemplate)
  /// [onToken] - Optional callback for each generated token
  /// 
  /// Returns the complete generated text
  Future<String> generate(
    String prompt, {
    void Function(String token)? onToken,
  }) async {
    final buffer = StringBuffer();
    
    await for (final token in generateStream(prompt)) {
      buffer.write(token);
      onToken?.call(token);
    }

    return buffer.toString();
  }

  /// Dispose of resources and cleanup
  Future<void> dispose() async {
    if (_llamaParent != null) {
      await _llamaParent!.dispose();
      _llamaParent = null;
    }
    _isInitialized = false;
    print('LlamaService: Disposed');
  }

  /// Get the full path to the model file
  Future<String?> _getModelPath(String fileName) async {
    try {
      // First check in models/ directory (for development)
      final devModelPath = 'models/$fileName';
      if (await File(devModelPath).exists()) {
        return devModelPath;
      }

      // Then check in app documents directory (for production)
      final appDir = await getApplicationDocumentsDirectory();
      final prodModelPath = '${appDir.path}/models/$fileName';
      if (await File(prodModelPath).exists()) {
        return prodModelPath;
      }

      print('LlamaService: Model not found in dev or prod paths');
      return null;
    } catch (e) {
      print('LlamaService: Error getting model path: $e');
      return null;
    }
  }

  /// Get the platform-specific llama.cpp library path
  Future<String?> _getLibraryPath() async {
    // The library should be bundled with the app
    // For now, return null to use default library discovery
    // TODO: Bundle llama.cpp library with the app
    return null;
  }
}

