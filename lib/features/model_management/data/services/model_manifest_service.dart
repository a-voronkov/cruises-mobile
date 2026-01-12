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
  ModelManifest getDefaultManifest() {
    return ModelManifest(
      version: 1,
      baseUrl: 'https://cruises.voronkov.club/models',
      recommendedModelId: 'lfm25-1.2b-q4km',
      models: [
        ModelInfo(
          id: 'lfm25-1.2b-q4km',
          name: 'LFM2.5 1.2B',
          version: '1.2B',
          description: 'Compact and efficient model for mobile devices. '
              'Great balance of quality and speed.',
          fileName: AppConstants.modelFileName,
          downloadUrl: AppConstants.modelDownloadUrl,
          sizeBytes: AppConstants.modelSizeBytes,
          quantization: QuantizationType.q4KM,
          capabilities: [
            ModelCapability.chat,
            ModelCapability.multilingual,
          ],
          contextSize: 32768,
          isRecommended: true,
          minRamMb: 700,
          languages: ['en', 'es', 'fr', 'de', 'pt', 'it', 'nl', 'ru'],
        ),
      ],
    );
  }

  /// Fetch manifest with fallback to default
  Future<ModelManifest> getManifest() async {
    final manifest = await fetchManifest();
    return manifest ?? getDefaultManifest();
  }
}

