import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../models/model_info.dart';
import 'hive_service.dart';

/// Service for downloading and managing the LLM model file
class ModelDownloadService {
  final Dio _dio;
  CancelToken? _cancelToken;

  /// Currently selected model filename (null = default from AppConstants)
  String? _selectedModelFileName;

  /// Currently selected model info (persisted in Hive settings box)
  ModelInfo? _selectedModel;

  ModelDownloadService({Dio? dio}) : _dio = dio ?? Dio() {
    _loadSelectedModelFromStorage();
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

  /// Set the selected model
  Future<void> selectModel(ModelInfo model) async {
    _selectedModel = model;
    _selectedModelFileName = model.fileName;

    try {
      await HiveService.settingsBox.put(AppConstants.modelStorageKey, model.toJson());
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

    // Check file size is reasonable (> 100MB for a valid model)
    final fileSize = file.lengthSync();
    return fileSize > 100 * 1024 * 1024;
  }

  /// Check if a specific model is downloaded
  Future<bool> isModelFileDownloaded(String fileName) async {
    final path = await getModelPathFor(fileName);
    if (path == null) return false;

    final file = File(path);
    if (!file.existsSync()) return false;

    final fileSize = file.lengthSync();
    return fileSize > 100 * 1024 * 1024;
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

      // Build download URL
      final downloadUrl = '${AppConstants.modelServerBaseUrl}/$fileName';

      // Create a new cancel token for this download
      _cancelToken = CancelToken();

      onProgress(0, 'Starting download...');

      // Download the model file
      await _dio.download(
        downloadUrl,
        modelPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
            onProgress(
              progress,
              'Downloading: $receivedMB MB / $totalMB MB',
            );
          } else {
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(1);
            onProgress(0.5, 'Downloading: $receivedMB MB');
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Verify download
      final file = File(modelPath);
      if (file.existsSync()) {
        final fileSize = file.lengthSync();
        if (fileSize > 100 * 1024 * 1024) {
          // Update selected model on successful download
          if (modelInfo != null) {
            await selectModel(modelInfo);
          }
          onProgress(1.0, 'Download complete!');
          return true;
        } else {
          onProgress(0, 'Error: Downloaded file is too small');
          file.deleteSync();
          return false;
        }
      }

      onProgress(0, 'Error: File not found after download');
      return false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        onProgress(0, 'Download cancelled');
      } else {
        onProgress(0, 'Download error: ${e.message}');
      }
      return false;
    } catch (e) {
      onProgress(0, 'Error: $e');
      return false;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
  }

  /// Delete the model file
  Future<bool> deleteModel() async {
    return deleteModelFile(currentModelFileName);
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
}

