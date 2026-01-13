import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Information about a model file on HuggingFace
class HFModelFile {
  final String path;
  final int size;
  final String? oid; // Git LFS object ID
  final String type; // 'file' or 'directory'

  HFModelFile({
    required this.path,
    required this.size,
    this.oid,
    required this.type,
  });

  factory HFModelFile.fromJson(Map<String, dynamic> json) {
    return HFModelFile(
      path: json['path'] as String,
      size: (json['size'] as num?)?.toInt() ?? 0,
      oid: json['oid'] as String?,
      type: json['type'] as String? ?? 'file',
    );
  }

  /// Get quantization type from filename (e.g., "int8", "fp16", "q4")
  String? get quantization {
    final fileName = path.toLowerCase();
    
    // ONNX quantization patterns
    if (fileName.contains('int8')) return 'INT8';
    if (fileName.contains('int4')) return 'INT4';
    if (fileName.contains('fp16')) return 'FP16';
    if (fileName.contains('fp32')) return 'FP32';
    
    // GGUF quantization patterns
    if (fileName.contains('q4_k_m')) return 'Q4_K_M';
    if (fileName.contains('q5_k_m')) return 'Q5_K_M';
    if (fileName.contains('q6_k')) return 'Q6_K';
    if (fileName.contains('q8_0')) return 'Q8_0';
    if (fileName.contains('f16')) return 'F16';
    
    return null;
  }

  /// Check if this is an ONNX model file
  bool get isONNX => path.toLowerCase().endsWith('.onnx');

  /// Check if this is a GGUF model file
  bool get isGGUF => path.toLowerCase().endsWith('.gguf');

  /// Format size in human readable format
  String get formattedSize {
    final mb = size / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }

  /// Get download URL for this file
  String getDownloadUrl(String repoId) {
    return 'https://huggingface.co/$repoId/resolve/main/$path';
  }
}

/// Service for fetching model files from HuggingFace
class HuggingFaceModelFilesService {
  final String? _apiKey;
  final http.Client _client;

  HuggingFaceModelFilesService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client();

  /// Get list of files for a model repository
  /// 
  /// [repoId] - HuggingFace repository ID (e.g., "meta-llama/Llama-3.2-1B-Instruct")
  /// [fileType] - Filter by file extension (e.g., "onnx", "gguf")
  Future<List<HFModelFile>> getModelFiles({
    required String repoId,
    String? fileType,
  }) async {
    try {
      final uri = Uri.parse('https://huggingface.co/api/models/$repoId/tree/main');
      
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };

      debugPrint('Fetching model files from: $uri');
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final files = data
            .map((json) => HFModelFile.fromJson(json as Map<String, dynamic>))
            .where((file) {
              // Filter out directories
              if (file.type != 'file') return false;

              // Filter by file type if specified
              if (fileType != null) {
                final ext = file.path.toLowerCase().split('.').last;
                if (ext != fileType.toLowerCase()) return false;
              }

              // Only include model files (ONNX or GGUF)
              return file.isONNX || file.isGGUF;
            })
            .toList();

        debugPrint('Found ${files.length} model files');
        return files;
      } else if (response.statusCode == 404) {
        debugPrint('Model repository not found: $repoId');
        return [];
      } else {
        debugPrint('HF API error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('Failed to fetch model files: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching model files: $e');
      rethrow;
    }
  }

  /// Get ONNX files grouped by quantization
  Future<Map<String, List<HFModelFile>>> getONNXFilesByQuantization(String repoId) async {
    final files = await getModelFiles(repoId: repoId, fileType: 'onnx');
    
    final grouped = <String, List<HFModelFile>>{};
    for (final file in files) {
      final quant = file.quantization ?? 'Unknown';
      grouped.putIfAbsent(quant, () => []).add(file);
    }
    
    return grouped;
  }

  void dispose() {
    _client.close();
  }
}

