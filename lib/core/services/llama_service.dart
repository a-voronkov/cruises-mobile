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
    Map<String, Object> diagnostics = {};

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

      // Read GGUF metadata for debugging before attempting to load
      debugPrint('LlamaService: Reading GGUF metadata...');
      final ggufMetadata = await readGgufMetadata(_modelPath!);
      diagnostics['gguf'] = ggufMetadata;

      debugPrint('LlamaService: GGUF version: ${ggufMetadata['ggufVersion']}');
      debugPrint('LlamaService: Architecture: ${ggufMetadata['architecture']}');
      debugPrint('LlamaService: Model name: ${ggufMetadata['modelName']}');
      debugPrint('LlamaService: Tensor count: ${ggufMetadata['tensorCount']}');
      debugPrint('LlamaService: Metadata KV count: ${ggufMetadata['metadataKvCount']}');

      if (ggufMetadata.containsKey('error')) {
        debugPrint('LlamaService: GGUF read error: ${ggufMetadata['error']}');
      }
      if (ggufMetadata.containsKey('metadataReadError')) {
        debugPrint('LlamaService: GGUF metadata read error: ${ggufMetadata['metadataReadError']}');
      }

      onProgress?.call(0.4);

      // Set library path based on platform
      final libraryPath = await _getLibraryPath();
      diagnostics['libraryPath'] = libraryPath ?? 'default (embedded)';

      if (libraryPath != null) {
        Llama.libraryPath = libraryPath;
      }

      onProgress?.call(0.5);
      diagnostics['initStage'] = 'pre_llama_init';
      diagnostics['useMemorymap'] = false; // Track mmap setting for debugging

      // llama_cpp_dart's params are configured via mutable properties (not
      // constructor named-args). Keep this compatible with older versions.
      //
      // IMPORTANT: useMemorymap = false is required on some Android devices
      // where SELinux prevents mmap of files in app_flutter directory.
      // This loads the entire model into RAM instead of memory-mapping.
      // Trade-off: higher RAM usage (~700MB) but more compatible.
      final modelParams = ModelParams()
        ..nGpuLayers = 0 // CPU inference for now, can enable GPU later
        ..vocabOnly = false
        ..useMemorymap = false // Disabled for Android SELinux compatibility
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
  Future<void> _reportDiagnostics(String message, Map<String, Object> diagnostics) async {
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

  /// Read GGUF file header and metadata for debugging
  ///
  /// GGUF format: https://github.com/ggerganov/ggml/blob/master/docs/gguf.md
  /// Returns a map with file metadata or error information
  Future<Map<String, dynamic>> readGgufMetadata(String filePath) async {
    final result = <String, dynamic>{};
    RandomAccessFile? file;

    try {
      final modelFile = File(filePath);
      if (!await modelFile.exists()) {
        result['error'] = 'File does not exist';
        return result;
      }

      file = await modelFile.open(mode: FileMode.read);

      // Read GGUF magic number (4 bytes): "GGUF" = 0x46554747
      final magic = await file.read(4);
      final magicStr = String.fromCharCodes(magic);
      result['magic'] = magicStr;
      result['magicHex'] = magic.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

      if (magicStr != 'GGUF') {
        result['error'] = 'Invalid GGUF magic: expected "GGUF", got "$magicStr"';
        return result;
      }

      // Read version (4 bytes, little-endian uint32)
      final versionBytes = await file.read(4);
      final version = versionBytes[0] | (versionBytes[1] << 8) |
                      (versionBytes[2] << 16) | (versionBytes[3] << 24);
      result['ggufVersion'] = version;

      // Read tensor count (8 bytes, little-endian uint64)
      final tensorCountBytes = await file.read(8);
      final tensorCount = _readUint64LE(tensorCountBytes);
      result['tensorCount'] = tensorCount;

      // Read metadata kv count (8 bytes, little-endian uint64)
      final kvCountBytes = await file.read(8);
      final kvCount = _readUint64LE(kvCountBytes);
      result['metadataKvCount'] = kvCount;

      // Try to read architecture from metadata
      // Metadata format: key (string), value_type (uint32), value
      // We'll read first few key-value pairs looking for "general.architecture"
      final metadata = <String, dynamic>{};
      int kvRead = 0;
      const maxKvToRead = 20; // Read first 20 kv pairs max

      while (kvRead < kvCount && kvRead < maxKvToRead) {
        try {
          // Read key length (8 bytes for GGUF v3)
          final keyLenBytes = await file.read(8);
          final keyLen = _readUint64LE(keyLenBytes);

          if (keyLen > 256) {
            // Sanity check - key shouldn't be too long
            result['metadataReadError'] = 'Key too long at kv $kvRead: $keyLen';
            break;
          }

          // Read key
          final keyBytes = await file.read(keyLen.toInt());
          final key = String.fromCharCodes(keyBytes);

          // Read value type (4 bytes)
          final valueTypeBytes = await file.read(4);
          final valueType = valueTypeBytes[0] | (valueTypeBytes[1] << 8) |
                           (valueTypeBytes[2] << 16) | (valueTypeBytes[3] << 24);

          // Read value based on type
          dynamic value;
          switch (valueType) {
            case 8: // GGUF_TYPE_STRING
              final strLenBytes = await file.read(8);
              final strLen = _readUint64LE(strLenBytes);
              if (strLen <= 1024) {
                final strBytes = await file.read(strLen.toInt());
                value = String.fromCharCodes(strBytes);
              } else {
                // Skip long strings
                await file.setPosition(await file.position() + strLen.toInt());
                value = '<string len=$strLen>';
              }
              break;
            case 4: // GGUF_TYPE_UINT32
              final uint32Bytes = await file.read(4);
              value = uint32Bytes[0] | (uint32Bytes[1] << 8) |
                     (uint32Bytes[2] << 16) | (uint32Bytes[3] << 24);
              break;
            case 5: // GGUF_TYPE_INT32
              final int32Bytes = await file.read(4);
              value = int32Bytes[0] | (int32Bytes[1] << 8) |
                     (int32Bytes[2] << 16) | (int32Bytes[3] << 24);
              break;
            case 6: // GGUF_TYPE_FLOAT32
              final f32Bytes = await file.read(4);
              value = '<float32>';
              break;
            case 7: // GGUF_TYPE_BOOL
              final boolBytes = await file.read(1);
              value = boolBytes[0] != 0;
              break;
            default:
              // For other types, we can't easily skip - break
              result['metadataReadError'] = 'Unsupported value type $valueType for key "$key"';
              break;
          }

          if (result.containsKey('metadataReadError')) break;

          metadata[key] = value;
          kvRead++;

          // Log important keys
          if (key == 'general.architecture' ||
              key == 'general.name' ||
              key == 'general.quantization_version' ||
              key.startsWith('llama.') ||
              key.startsWith('lfm')) {
            debugPrint('GGUF metadata: $key = $value');
          }
        } catch (e) {
          result['metadataReadError'] = 'Error reading kv $kvRead: $e';
          break;
        }
      }

      result['metadata'] = metadata;
      result['architecture'] = metadata['general.architecture'] ?? 'unknown';
      result['modelName'] = metadata['general.name'] ?? 'unknown';

    } catch (e) {
      result['error'] = 'Failed to read GGUF: $e';
    } finally {
      await file?.close();
    }

    return result;
  }

  /// Read uint64 from little-endian bytes
  int _readUint64LE(List<int> bytes) {
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24) |
           (bytes[4] << 32) | (bytes[5] << 40) | (bytes[6] << 48) | (bytes[7] << 56);
  }
}

