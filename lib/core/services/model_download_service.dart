import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Service for downloading and managing the LLM model file
class ModelDownloadService {
  final Dio _dio;
  CancelToken? _cancelToken;

  ModelDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  /// Check if the model file exists locally
  Future<bool> isModelDownloaded() async {
    final modelPath = await getModelPath();
    if (modelPath == null) return false;
    
    final file = File(modelPath);
    if (!await file.exists()) return false;
    
    // Check file size is reasonable (> 100MB for a valid model)
    final fileSize = await file.length();
    return fileSize > 100 * 1024 * 1024;
  }

  /// Get the local path where the model should be stored
  Future<String?> getModelPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');
      
      // Create models directory if it doesn't exist
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }
      
      return '${modelsDir.path}/${AppConstants.modelFileName}';
    } catch (e) {
      print('Error getting model path: $e');
      return null;
    }
  }

  /// Download the model with progress callback
  /// 
  /// [onProgress] - Callback with progress (0.0 to 1.0) and status message
  /// Returns true if download was successful
  Future<bool> downloadModel({
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      final modelPath = await getModelPath();
      if (modelPath == null) {
        onProgress(0, 'Error: Could not determine download path');
        return false;
      }

      // Create a new cancel token for this download
      _cancelToken = CancelToken();

      onProgress(0, 'Starting download...');

      // Download the model file
      await _dio.download(
        AppConstants.modelDownloadUrl,
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
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 100 * 1024 * 1024) {
          onProgress(1.0, 'Download complete!');
          return true;
        } else {
          onProgress(0, 'Error: Downloaded file is too small');
          await file.delete();
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
    try {
      final modelPath = await getModelPath();
      if (modelPath == null) return false;
      
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting model: $e');
      return false;
    }
  }

  /// Get the size of the downloaded model file
  Future<int?> getModelSize() async {
    try {
      final modelPath = await getModelPath();
      if (modelPath == null) return null;
      
      final file = File(modelPath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

