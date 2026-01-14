import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/model_info.dart';
import '../../domain/entities/model_manifest.dart';

/// Service for fetching and managing model manifests
class ModelManifestService {
  final Dio _dio;

  ModelManifestService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch the model manifest from the server
  Future<ModelManifest?> fetchManifest() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.modelManifestUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data != null) {
        return ModelManifest.fromJson(response.data!);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('ModelManifestService: Failed to fetch manifest: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('ModelManifestService: Error parsing manifest: $e');
      return null;
    }
  }

  /// Get the default manifest with hardcoded model info
  /// Used as fallback when network is unavailable
  ///
  /// Note: This returns a placeholder. Users should use Model Search to find ONNX models.
  ModelManifest getDefaultManifest() {
    return ModelManifest(
      version: 1,
      baseUrl: 'https://huggingface.co',
      recommendedModelId: 'search-for-models',
      models: [
        ModelInfo(
          id: 'search-for-models',
          name: 'Search for ONNX Models',
          version: '1.0',
          description: 'Use the Model Search feature to find and download ONNX models from HuggingFace.\n\n'
              'Recommended models:\n'
              '• onnx-community/Llama-3.2-1B-Instruct-ONNX (1.15 GB)\n'
              '• onnx-community/Phi-3-mini-4k-instruct-ONNX (2.3 GB)\n\n'
              'Tap the search icon to browse available models.',
          fileName: 'placeholder.onnx',
          downloadUrl: '',
          sizeBytes: 0,
          quantization: QuantizationType.q4KM,
          capabilities: [
            ModelCapability.chat,
          ],
          contextSize: 4096,
          isRecommended: true,
          minRamMb: 1000,
          languages: ['en'],
        ),
      ],
    );
  }

  /// Fetch manifest with fallback to default
  Future<ModelManifest> getManifest() async {
    // Always return default manifest for now
    // The old manifest URL is deprecated and returns HTML instead of JSON
    debugPrint('ModelManifestService: Using default manifest (network manifest deprecated)');
    return getDefaultManifest();
  }
}

