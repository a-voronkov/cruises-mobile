import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with HuggingFace API
class HuggingFaceService {
  final String? _token;
  final http.Client _client;

  static const String _baseUrl = 'https://huggingface.co';
  static const String _apiUrl = 'https://huggingface.co/api';

  HuggingFaceService({
    String? token,
    http.Client? client,
  })  : _token = token,
        _client = client ?? http.Client();

  /// Get list of files in a HuggingFace repository
  /// 
  /// [repoId] - Repository ID (e.g., "LiquidAI/LFM2.5-1.2B-Instruct-ONNX")
  /// [revision] - Git revision (branch, tag, or commit hash). Defaults to "main"
  Future<List<HuggingFaceFile>> listFiles(
    String repoId, {
    String revision = 'main',
  }) async {
    try {
      final url = Uri.parse('$_apiUrl/models/$repoId/tree/$revision');
      
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> files = json.decode(response.body) as List;
        return files
            .map((file) => HuggingFaceFile.fromJson(file as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('HuggingFaceService: Failed to list files: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('HuggingFaceService: Error listing files: $e');
      return [];
    }
  }

  /// Get download URL for a file in a HuggingFace repository
  /// 
  /// [repoId] - Repository ID (e.g., "LiquidAI/LFM2.5-1.2B-Instruct-ONNX")
  /// [fileName] - File name (e.g., "model.onnx")
  /// [revision] - Git revision (branch, tag, or commit hash). Defaults to "main"
  String getDownloadUrl(
    String repoId,
    String fileName, {
    String revision = 'main',
  }) {
    return '$_baseUrl/$repoId/resolve/$revision/$fileName';
  }

  /// Get repository metadata
  Future<Map<String, dynamic>?> getRepoMetadata(String repoId) async {
    try {
      final url = Uri.parse('$_apiUrl/models/$repoId');
      
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('HuggingFaceService: Failed to get metadata: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('HuggingFaceService: Error getting metadata: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Information about a file in a HuggingFace repository
class HuggingFaceFile {
  final String path;
  final String type; // "file" or "directory"
  final int? size;
  final String? oid; // Git object ID

  const HuggingFaceFile({
    required this.path,
    required this.type,
    this.size,
    this.oid,
  });

  factory HuggingFaceFile.fromJson(Map<String, dynamic> json) {
    return HuggingFaceFile(
      path: json['path'] as String,
      type: json['type'] as String,
      size: json['size'] as int?,
      oid: json['oid'] as String?,
    );
  }

  bool get isFile => type == 'file';
  bool get isDirectory => type == 'directory';

  /// Check if this is an ONNX model file
  bool get isOnnxModel => isFile && path.toLowerCase().endsWith('.onnx');

  /// Check if this is a quantized ONNX model
  bool get isQuantized => isOnnxModel && (
    path.contains('int4') ||
    path.contains('int8') ||
    path.contains('fp16') ||
    path.contains('uint4') ||
    path.contains('uint8')
  );

  /// Extract quantization type from filename
  String? get quantizationType {
    if (!isQuantized) return null;
    
    final lower = path.toLowerCase();
    if (lower.contains('int4') || lower.contains('uint4')) return 'INT4';
    if (lower.contains('int8') || lower.contains('uint8')) return 'INT8';
    if (lower.contains('fp16')) return 'FP16';
    return null;
  }

  /// Format size in human readable format
  String get formattedSize {
    if (size == null) return 'Unknown';
    
    final mb = size! / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }
}

