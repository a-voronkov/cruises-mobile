import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:background_downloader/background_downloader.dart';
import '../constants/app_constants.dart';
import '../models/model_info.dart';
import 'hive_service.dart';
import 'ai_service.dart';
import 'network_monitor_service.dart';

/// Service for downloading and managing the LLM model file
class ModelDownloadService {
  final Dio _dio;
  final AIService? _aiService;
  final NetworkMonitorService _networkMonitor;
  DownloadTask? _currentTask;

  StreamSubscription<bool>? _networkSubscription;
  bool _shouldResumeOnReconnect = false;
  String? _pausedDownloadUrl;
  String? _pausedDownloadPath;
  void Function(double, String)? _pausedProgressCallback;

  /// Currently selected model filename (null = default from AppConstants)
  String? _selectedModelFileName;

  /// Currently selected model info (persisted in Hive settings box)
  ModelInfo? _selectedModel;

  ModelDownloadService({
    Dio? dio,
    AIService? aiService,
    NetworkMonitorService? networkMonitor,
  })  : _dio = dio ?? Dio(),
        _aiService = aiService,
        _networkMonitor = networkMonitor ?? NetworkMonitorService() {
    _loadSelectedModelFromStorage();
    _initializeBackgroundDownloader();
    _initializeNetworkMonitoring();
  }

  /// Initialize network monitoring for auto-resume
  void _initializeNetworkMonitoring() {
    _networkMonitor.initialize();

    _networkSubscription = _networkMonitor.connectivityStream.listen((isConnected) {
      if (isConnected && _shouldResumeOnReconnect) {
        debugPrint('NetworkMonitor: Internet restored, resuming download...');
        _resumeDownload();
      }
    });
  }

  /// Initialize background downloader
  Future<void> _initializeBackgroundDownloader() async {
    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(hours: 24)),
        (Config.holdingQueue, (maxConcurrent: 1, maxWaitingTasks: 10)),
      ],
      androidConfig: [
        (Config.useCacheDir, Config.whenAble),
        (Config.runInForeground, Config.always),
        (Config.checkAvailableSpace, Config.always),
      ],
      iOSConfig: [
        (Config.localize, {'Cancel': 'Cancel', 'Pause': 'Pause', 'Resume': 'Resume'}),
      ],
    );

    debugPrint('Background downloader initialized');
  }

  void _loadSelectedModelFromStorage() {
    try {
      final raw = HiveService.settingsBox.get(AppConstants.modelStorageKey);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        _selectedModel = ModelInfo.fromJson(map);
        _selectedModelFileName = _selectedModel?.fileName;
      }
    } catch (e) {
      // Hive may not be initialized yet or stored data may be incompatible.
      // Fall back to default model.
      debugPrint('ModelDownloadService: failed to load selected model: $e');
    }
  }

  /// Get the current model filename
  String get currentModelFileName =>
      _selectedModelFileName ?? AppConstants.modelFileName;

  /// Get the currently selected model (if stored)
  ModelInfo? get selectedModel => _selectedModel;

  /// Set the selected model and initialize AI service with it
  Future<void> selectModel(ModelInfo model) async {
    _selectedModel = model;
    _selectedModelFileName = model.fileName;

    try {
      await HiveService.settingsBox.put(AppConstants.modelStorageKey, model.toJson());
      debugPrint('ModelDownloadService: Model saved: ${model.huggingFaceRepo}');

      // Initialize AI service with this model if available
      if (_aiService != null && model.huggingFaceRepo != null) {
        debugPrint('ModelDownloadService: Initializing AI service with model: ${model.huggingFaceRepo}');

        final success = await _aiService!.initialize(
          modelId: model.huggingFaceRepo!,
          modelFileName: model.fileName,
          onProgress: (progress) {
            debugPrint('Model initialization progress: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );

        if (success) {
          debugPrint('ModelDownloadService: Successfully initialized with ${model.huggingFaceRepo}');
        } else {
          debugPrint('ModelDownloadService: Failed to initialize with ${model.huggingFaceRepo}');
        }
      }
    } catch (e) {
      debugPrint('ModelDownloadService: failed to persist selected model: $e');
    }
  }

  /// Clear persisted model selection (falls back to default model)
  Future<void> clearSelectedModel() async {
    _selectedModel = null;
    _selectedModelFileName = null;
    try {
      await HiveService.settingsBox.delete(AppConstants.modelStorageKey);
    } catch (e) {
      debugPrint('ModelDownloadService: failed to clear selected model: $e');
    }
  }

  /// Fetch available models from server manifest
  Future<ModelManifest?> fetchModelManifest() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.modelManifestUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data != null) {
        return ModelManifest.fromJson(response.data!);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Error fetching manifest: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error parsing manifest: $e');
      return null;
    }
  }

  /// Check if the model file exists locally
  Future<bool> isModelDownloaded() async {
    final modelPath = await getModelPath();
    if (modelPath == null) return false;

    final file = File(modelPath);
    if (!file.existsSync()) return false;

    // Check file size is reasonable (> 100MB for a valid model file)
    // Skip size check for small files like tokenizer configs
    final fileSize = file.lengthSync();
    final fileName = file.path.toLowerCase();

    // Only check size for actual model files (.onnx, .gguf)
    if (fileName.endsWith('.onnx') || fileName.endsWith('.gguf')) {
      return fileSize > 100 * 1024 * 1024;
    }

    // For other files (tokenizer, configs), just check they exist and have content
    return fileSize > 0;
  }

  /// Check if a specific model is downloaded
  Future<bool> isModelFileDownloaded(String fileName) async {
    final path = await getModelPathFor(fileName);
    if (path == null) return false;

    final file = File(path);
    if (!file.existsSync()) return false;

    final fileSize = file.lengthSync();
    final fileNameLower = fileName.toLowerCase();

    // Only check size for actual model files (.onnx, .gguf)
    if (fileNameLower.endsWith('.onnx') || fileNameLower.endsWith('.gguf')) {
      return fileSize > 100 * 1024 * 1024;
    }

    // For other files (tokenizer, configs), just check they exist and have content
    return fileSize > 0;
  }

  /// Get the local path where the model should be stored
  Future<String?> getModelPath() async {
    return getModelPathFor(currentModelFileName);
  }

  /// Get model path for a specific filename
  Future<String?> getModelPathFor(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');

      // Create models directory if it doesn't exist
      if (!modelsDir.existsSync()) {
        modelsDir.createSync(recursive: true);
      }

      return '${modelsDir.path}/$fileName';
    } catch (e) {
      debugPrint('Error getting model path: $e');
      return null;
    }
  }

  /// Get list of all downloaded model files
  Future<List<String>> getDownloadedModels() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');

      if (!modelsDir.existsSync()) return [];

      return modelsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.gguf'))
          .map((f) => f.path.split('/').last)
          .toList();
    } catch (e) {
      debugPrint('Error listing models: $e');
      return [];
    }
  }

  /// Resume paused download
  Future<void> _resumeDownload() async {
    if (_pausedDownloadUrl == null || _pausedDownloadPath == null || _pausedProgressCallback == null) {
      debugPrint('Cannot resume: missing download info');
      return;
    }

    if (_currentTask == null) {
      debugPrint('Cannot resume: no current task');
      return;
    }

    debugPrint('Resuming download: ${_currentTask!.filename}');
    _shouldResumeOnReconnect = false;

    // Resume the task
    final resumed = await FileDownloader().resume(_currentTask!);
    if (!resumed) {
      debugPrint('Failed to resume download');
      _pausedProgressCallback!(0, 'Failed to resume download');
    }
  }

  /// Download the model with progress callback
  ///
  /// [onProgress] - Callback with progress (0.0 to 1.0) and status message
  /// [modelInfo] - Optional specific model to download. Uses current model if null.
  /// Returns true if download was successful
  Future<bool> downloadModel({
    required void Function(double progress, String status) onProgress,
    ModelInfo? modelInfo,
  }) async {
    try {
      final fileName = modelInfo?.fileName ?? currentModelFileName;
      final modelPath = await getModelPathFor(fileName);
      if (modelPath == null) {
        onProgress(0, 'Error: Could not determine download path');
        return false;
      }

      // Build download URL - use custom URL if provided, otherwise use default server
      final downloadUrl = modelInfo?.downloadUrl ?? '${AppConstants.modelServerBaseUrl}/$fileName';

      // Store download info for resume
      _pausedDownloadUrl = downloadUrl;
      _pausedDownloadPath = modelPath;
      _pausedProgressCallback = onProgress;

      onProgress(0, 'Starting download...');
      debugPrint('📥 Starting download: $fileName from $downloadUrl');

      // Get directory for download
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');
      if (!modelsDir.existsSync()) {
        modelsDir.createSync(recursive: true);
      }

      // Create download task with unique taskId
      final taskId = '${fileName}_${DateTime.now().millisecondsSinceEpoch}';
      final task = DownloadTask(
        taskId: taskId,
        url: downloadUrl,
        filename: fileName,
        directory: 'models',
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        requiresWiFi: false,
        retries: 5,
        allowPause: true,
        metaData: modelInfo?.id ?? fileName,
        // Add headers for HuggingFace compatibility
        headers: {
          'User-Agent': 'Mozilla/5.0 (Android; Mobile) AppleWebKit/537.36',
        },
        // Allow redirects (HuggingFace uses CDN redirects)
        post: null,
      );

      // Store task
      _currentTask = task;

      debugPrint('📦 Created download task: $taskId for $fileName');

      // Track completion
      var isComplete = false;
      var hasFailed = false;
      var lastProgress = 0.0;
      var lastProgressTime = DateTime.now();

      // Start download and listen to updates with timeout
      debugPrint('🚀 Calling FileDownloader().download() for $fileName');
      final downloadFuture = FileDownloader().download(
        task,
        onProgress: (progress) {
          // This callback is called for progress updates
          lastProgress = progress;
          lastProgressTime = DateTime.now();
          debugPrint('📊 Download progress for $fileName: ${(progress * 100).toStringAsFixed(1)}%');
          onProgress(progress, 'Downloading: ${(progress * 100).toStringAsFixed(0)}%');
        },
        onStatus: (status) {
          // This callback is called for status changes
          debugPrint('📡 Download status for $fileName: $status');
          debugPrint('📌 Download status for $fileName: $status');
          switch (status) {
            case TaskStatus.enqueued:
              debugPrint('⏳ Download enqueued for $fileName');
              break;
            case TaskStatus.running:
              debugPrint('▶️ Download started for $fileName');
              break;
            case TaskStatus.complete:
              isComplete = true;
              onProgress(1.0, 'Download complete!');
              _shouldResumeOnReconnect = false;
              break;
            case TaskStatus.failed:
              hasFailed = true;
              // Check if it's a network error
              if (!_networkMonitor.isConnected) {
                debugPrint('Download failed due to network loss, will resume when connected');
                _shouldResumeOnReconnect = true;
                onProgress(0, 'Waiting for internet connection...');
              } else {
                debugPrint('❌ Download failed for $fileName');
                onProgress(0, 'Download failed');
                _shouldResumeOnReconnect = false;
              }
              break;
            case TaskStatus.canceled:
              hasFailed = true;
              onProgress(0, 'Download cancelled');
              _shouldResumeOnReconnect = false;
              break;
            case TaskStatus.paused:
              onProgress(0, 'Download paused');
              // Don't set resume flag for manual pause
              break;
            case TaskStatus.notFound:
              hasFailed = true;
              debugPrint('❌ File not found (404) for $fileName');
              onProgress(0, 'File not found');
              _shouldResumeOnReconnect = false;
              break;
            default:
              debugPrint('⚠️ Unknown status: $status for $fileName');
              break;
          }
        },
      );

      // Wait for download with timeout (30 minutes for large files)
      final result = await downloadFuture.timeout(
        const Duration(minutes: 30),
        onTimeout: () {
          debugPrint('⏱️ Download timeout for $fileName after 30 minutes');
          hasFailed = true;
          onProgress(0, 'Download timeout');
          return TaskStatusUpdate(task, TaskStatus.failed);
        },
      );

      debugPrint('✅ Download completed with status: ${result.status} for $fileName');

      // Verify download
      debugPrint('🔍 Verifying download for $fileName...');

      if (result.status == TaskStatus.complete && isComplete) {
        final file = File(modelPath);
        if (file.existsSync()) {
          final fileSize = file.lengthSync();
          final fileNameLower = fileName.toLowerCase();

          debugPrint('📁 File exists: $modelPath (${fileSize} bytes)');

          // Check if file is a Git LFS pointer
          bool isLfsPointer = false;
          if (fileSize < 200) {
            try {
              final content = file.readAsStringSync();
              if (content.startsWith('version https://git-lfs.github.com')) {
                isLfsPointer = true;
                debugPrint('⚠️ Downloaded Git LFS pointer instead of actual file!');
                debugPrint('Content: $content');
              }
            } catch (e) {
              debugPrint('Could not read file to check for LFS pointer: $e');
            }
          }

          // Check file size based on file type
          bool isValidSize = false;
          if (isLfsPointer) {
            // LFS pointer file - this is an error
            isValidSize = false;
            debugPrint('❌ File is a Git LFS pointer, not the actual file');
          } else if (fileNameLower.endsWith('.onnx') || fileNameLower.endsWith('.gguf')) {
            // Main model files should be > 100MB
            // But some auxiliary ONNX files (embedding, speech, vision) might be smaller
            // Accept files > 1KB as valid (to allow small auxiliary files)
            isValidSize = fileSize > 1024;
            if (!isValidSize) {
              debugPrint('❌ Model file too small: ${fileSize / 1024 / 1024} MB');
            } else if (fileSize > 100 * 1024 * 1024) {
              debugPrint('✅ Large model file size OK: ${fileSize / 1024 / 1024} MB');
            } else {
              debugPrint('✅ Small model file size OK: ${fileSize / 1024 / 1024} MB (auxiliary file)');
            }
          } else {
            // Tokenizer and config files just need to have content
            isValidSize = fileSize > 0;
            debugPrint('✅ Config file detected (${fileSize} bytes): $fileName');
          }

          if (isValidSize) {
            // Don't initialize AI service here - wait until all files are downloaded
            // Just save the model info for later
            if (modelInfo != null && (fileNameLower.endsWith('.onnx') || fileNameLower.endsWith('.gguf'))) {
              debugPrint('💾 Saving model info: ${modelInfo.id}');
              _selectedModel = modelInfo;
              _selectedModelFileName = fileName;
              try {
                await HiveService.settingsBox.put(AppConstants.modelStorageKey, modelInfo.toJson());
                debugPrint('ModelDownloadService: Model info saved (without initialization): ${modelInfo.id}');
              } catch (e) {
                debugPrint('ModelDownloadService: failed to save model: $e');
              }
            }
            _currentTask = null;
            debugPrint('✅ Download verified successfully for $fileName');
            return true;
          } else {
            debugPrint('❌ File size validation failed for $fileName');
            onProgress(0, 'Error: Downloaded file is too small');
            file.deleteSync();
            _currentTask = null;
            return false;
          }
        } else {
          debugPrint('❌ File not found after download: $modelPath');
        }
      } else if (hasFailed) {
        debugPrint('❌ Download failed for $fileName');
      } else {
        debugPrint('⚠️ Download status unclear for $fileName: ${result.status}');
      }

      _currentTask = null;
      return false;
    } catch (e) {
      debugPrint('Download error: $e');
      onProgress(0, 'Error: $e');
      _currentTask = null;
      return false;
    }
  }

  /// Cancel ongoing download
  Future<void> cancelDownload() async {
    if (_currentTask != null) {
      await FileDownloader().cancelTaskWithId(_currentTask!.taskId);
      _currentTask = null;
    }
  }

  /// Pause ongoing download
  Future<bool> pauseDownload() async {
    if (_currentTask != null) {
      return await FileDownloader().pause(_currentTask!);
    }
    return false;
  }

  /// Resume paused download
  Future<bool> resumeDownload() async {
    if (_currentTask != null) {
      return await FileDownloader().resume(_currentTask!);
    }
    return false;
  }

  /// Delete the model file
  Future<bool> deleteModel() async {
    return deleteModelFile(currentModelFileName);
  }

  /// Delete all downloaded models and related files
  Future<bool> deleteAllModels() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');

      if (modelsDir.existsSync()) {
        debugPrint('Deleting all models from: ${modelsDir.path}');
        modelsDir.deleteSync(recursive: true);

        // Clear selected model
        await clearSelectedModel();

        debugPrint('All models deleted successfully');
        return true;
      }

      debugPrint('Models directory does not exist');
      return false;
    } catch (e) {
      debugPrint('Error deleting all models: $e');
      return false;
    }
  }

  /// Delete a specific model file
  Future<bool> deleteModelFile(String fileName) async {
    try {
      final modelPath = await getModelPathFor(fileName);
      if (modelPath == null) return false;

      final file = File(modelPath);
      if (file.existsSync()) {
        file.deleteSync();

        // If we deleted the selected model, clear selection to avoid pointing
        // at a missing file.
        if (fileName == _selectedModelFileName) {
          await clearSelectedModel();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting model: $e');
      return false;
    }
  }

  /// Get the size of the downloaded model file
  Future<int?> getModelSize() async {
    return getModelSizeFor(currentModelFileName);
  }

  /// Get size of a specific model file
  Future<int?> getModelSizeFor(String fileName) async {
    try {
      final modelPath = await getModelPathFor(fileName);
      if (modelPath == null) return null;

      final file = File(modelPath);
      if (file.existsSync()) {
        return file.lengthSync();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _networkSubscription?.cancel();
    _networkMonitor.dispose();
  }
}

