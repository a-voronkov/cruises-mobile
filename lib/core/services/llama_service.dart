import 'dart:io';
import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
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
    // Diagnostic info collected during initialization
    Map<String, dynamic> diagnostics = {};

    try {
      if (_isInitialized) {
        debugPrint('LlamaService: Already initialized');
        return true;
      }

      onProgress?.call(0.1);

      // Get model path
      final fileName = modelFileName ?? AppConstants.modelFileName;
      _modelPath = await _getModelPath(fileName);

      // Collect diagnostic information
      diagnostics['expectedModelFileName'] = fileName;
      diagnostics['resolvedModelPath'] = _modelPath ?? 'null';
      diagnostics['appDocumentsDir'] = (await getApplicationDocumentsDirectory()).path;
      diagnostics['platform'] = Platform.operatingSystem;
      diagnostics['platformVersion'] = Platform.operatingSystemVersion;

      if (_modelPath == null) {
        diagnostics['modelExists'] = false;
        diagnostics['error'] = 'Model path is null';
        await _reportDiagnostics('Model path resolution failed', diagnostics);
        return false;
      }

      final modelFile = File(_modelPath!);
      final modelExists = modelFile.existsSync();
      diagnostics['modelExists'] = modelExists;

      if (!modelExists) {
        diagnostics['error'] = 'Model file not found';
        await _reportDiagnostics('Model file not found', diagnostics);
        debugPrint('LlamaService: Model file not found at $_modelPath');
        return false;
      }

      // Validate model file size (should be at least 100MB for a valid GGUF model)
      final fileSize = await modelFile.length();
      final fileStat = await modelFile.stat();
      const minValidSize = 100 * 1024 * 1024; // 100MB minimum

      diagnostics['fileSizeBytes'] = fileSize;
      diagnostics['fileSizeMB'] = (fileSize / 1024 / 1024).toStringAsFixed(2);
      diagnostics['expectedSizeBytes'] = AppConstants.modelSizeBytes;
      diagnostics['expectedSizeMB'] = (AppConstants.modelSizeBytes / 1024 / 1024).toStringAsFixed(2);
      diagnostics['fileModified'] = fileStat.modified.toIso8601String();
      diagnostics['fileMode'] = fileStat.mode.toString();

      if (fileSize < minValidSize) {
        diagnostics['error'] = 'Model file too small (possibly corrupted or incomplete download)';
        await _reportDiagnostics('Model file validation failed', diagnostics);
        debugPrint('LlamaService: Model file too small ($fileSize bytes). '
            'Expected at least $minValidSize bytes. File may be corrupted.');
        return false;
      }

      debugPrint('LlamaService: Model file size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');

      onProgress?.call(0.3);

      // Set library path based on platform
      final libraryPath = await _getLibraryPath();
      diagnostics['libraryPath'] = libraryPath ?? 'default (embedded)';

      if (libraryPath != null) {
        Llama.libraryPath = libraryPath;
      }

      onProgress?.call(0.5);
      diagnostics['initStage'] = 'pre_llama_init';

      // llama_cpp_dart's params are configured via mutable properties (not
      // constructor named-args). Keep this compatible with older versions.
      final modelParams = ModelParams()
        ..nGpuLayers = 0 // CPU inference for now, can enable GPU later
        ..vocabOnly = false
        ..useMemorymap = true
        ..useMemoryLock = false;

      final contextParams = ContextParams()
        ..nCtx = AppConstants.contextLength
        ..nBatch = 512
        ..nThreads = AppConstants.numThreads
        ..nThreadsBatch = AppConstants.numThreads;

      final samplingParams = SamplerParams()
        ..temp = AppConstants.temperature
        ..topK = AppConstants.topK
        ..topP = AppConstants.topP
        ..minP = 0.05
        ..typical = 1.0
        ..penaltyLastTokens = 64
        ..penaltyRepeat = AppConstants.repetitionPenalty
        ..penaltyFreq = 0.0
        ..penaltyPresent = 0.0
        ..mirostatTau = 5.0
        ..mirostatEta = 0.1
        ..penaltyNewline = false
        ..seed = 0xFFFFFFFF;

      // Create load command with LFM2.5 optimized parameters
      // Note: ChatML format is configured via ModelParams.formatter in llama_cpp_dart 0.2.x
      modelParams.formatter = ChatMLFormat();

      final loadCommand = LlamaLoad(
        path: _modelPath!,
        modelParams: modelParams,
        contextParams: contextParams,
        samplingParams: samplingParams,
      );

      onProgress?.call(0.7);

      // Initialize LlamaParent (runs in isolate for non-blocking)
      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init();

      onProgress?.call(1.0);

      _isInitialized = true;
      debugPrint('LlamaService: Initialized successfully with model: $_modelPath');
      return true;
    } catch (e, stackTrace) {
      debugPrint('LlamaService: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Add error info to diagnostics
      diagnostics['error'] = e.toString();
      diagnostics['stage'] = 'llama_init';

      // Report to Bugsnag with full diagnostics
      await bugsnag.notify(
        e,
        stackTrace,
        callback: (event) {
          event.addMetadata('llama', diagnostics);
          event.addMetadata('app_config', {
            'modelFileName': AppConstants.modelFileName,
            'modelServerBaseUrl': AppConstants.modelServerBaseUrl,
            'contextLength': AppConstants.contextLength,
            'numThreads': AppConstants.numThreads,
            'temperature': AppConstants.temperature,
          });
          return true;
        },
      );

      _isInitialized = false;
      return false;
    }
  }

  /// Report diagnostics to Bugsnag for debugging
  Future<void> _reportDiagnostics(String message, Map<String, dynamic> diagnostics) async {
    await bugsnag.notify(
      Exception(message),
      StackTrace.current,
      callback: (event) {
        event.addMetadata('llama', diagnostics);
        event.addMetadata('app_config', {
          'modelFileName': AppConstants.modelFileName,
          'modelServerBaseUrl': AppConstants.modelServerBaseUrl,
          'contextLength': AppConstants.contextLength,
          'numThreads': AppConstants.numThreads,
        });
        return true;
      },
    );
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
    debugPrint('LlamaService: Disposed');
  }

  /// Get the full path to the model file
  Future<String?> _getModelPath(String fileName) async {
    try {
      // First check in models/ directory (for development)
      final devModelPath = 'models/$fileName';
      if (File(devModelPath).existsSync()) {
        return devModelPath;
      }

      // Then check in app documents directory (for production)
      final appDir = await getApplicationDocumentsDirectory();
      final prodModelPath = '${appDir.path}/models/$fileName';
      if (File(prodModelPath).existsSync()) {
        return prodModelPath;
      }

      debugPrint('LlamaService: Model not found in dev or prod paths');
      return null;
    } catch (e) {
      debugPrint('LlamaService: Error getting model path: $e');
      return null;
    }
  }

  /// Get the platform-specific llama.cpp library path
  Future<String?> _getLibraryPath() async {
    // llama_cpp_dart defaults to "libmtmd.so" on Android which is wrong.
    // We need to explicitly set "libllama.so" as the main library.
    // The libmtmd.so (multimodal) is optional and loaded separately by the library.
    if (Platform.isAndroid) {
      return 'libllama.so';
    }
    if (Platform.isIOS) {
      // On iOS, the library is embedded in the app bundle
      // llama_cpp_dart will find it via DynamicLibrary.process()
      return null;
    }
    // Other platforms: use default discovery
    return null;
  }
}

