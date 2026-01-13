import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model information from HuggingFace API
class HFModelInfo {
  final String id;
  final String author;
  final String modelName;
  final List<String> tags;
  final int? downloads;
  final int? likes;
  final String? description;
  final DateTime? lastModified;
  final Map<String, dynamic>? safetensors;

  HFModelInfo({
    required this.id,
    required this.author,
    required this.modelName,
    required this.tags,
    this.downloads,
    this.likes,
    this.description,
    this.lastModified,
    this.safetensors,
  });

  factory HFModelInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['modelId'] as String? ?? '';
    final parts = id.split('/');
    final author = parts.length > 1 ? parts[0] : 'unknown';
    final modelName = parts.length > 1 ? parts.sublist(1).join('/') : id;

    return HFModelInfo(
      id: id,
      author: author,
      modelName: modelName,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      downloads: json['downloads'] as int?,
      likes: json['likes'] as int?,
      description: json['description'] as String?,
      lastModified: json['lastModified'] != null 
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
      safetensors: json['safetensors'] as Map<String, dynamic>?,
    );
  }

  /// Estimate model size in billions of parameters from tags or safetensors
  double? get estimatedSizeB {
    // Try to extract from tags like "7b", "1.3b", etc.
    for (final tag in tags) {
      final match = RegExp(r'(\d+\.?\d*)b', caseSensitive: false).firstMatch(tag);
      if (match != null) {
        return double.tryParse(match.group(1)!);
      }
    }

    // Try to extract from model name
    final nameMatch = RegExp(r'(\d+\.?\d*)b', caseSensitive: false).firstMatch(modelName);
    if (nameMatch != null) {
      return double.tryParse(nameMatch.group(1)!);
    }

    // Try to estimate from safetensors total size (very rough estimate)
    if (safetensors != null && safetensors!['total'] != null) {
      final totalBytes = safetensors!['total'] as int;
      // Very rough: 1B params ≈ 2GB in fp16, ≈ 1GB in int8
      // Assume int8 quantization for ONNX models
      return totalBytes / (1024 * 1024 * 1024);
    }

    return null;
  }

  bool get isONNX => tags.contains('onnx');
}

/// Service for searching models on HuggingFace
class HuggingFaceModelSearchService {
  final String? _apiKey;
  final http.Client _client;
  static const String _baseUrl = 'https://huggingface.co/api';

  HuggingFaceModelSearchService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client();

  /// Search for ONNX models with size limit
  /// 
  /// [query] - Search query (optional)
  /// [maxSizeB] - Maximum model size in billions of parameters (default: 7)
  /// [limit] - Maximum number of results (default: 100)
  /// [sort] - Sort order: 'downloads', 'likes', 'lastModified' (default: 'downloads')
  Future<List<HFModelInfo>> searchONNXModels({
    String? query,
    double maxSizeB = 7.0,
    int limit = 100,
    String sort = 'downloads',
  }) async {
    try {
      final params = <String, String>{
        'filter': 'onnx',
        'sort': sort,
        'direction': '-1', // Descending
        'limit': limit.toString(),
        if (query != null && query.isNotEmpty) 'search': query,
      };

      final uri = Uri.parse('$_baseUrl/models').replace(queryParameters: params);
      
      final headers = <String, String>{
        'Accept': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };

      debugPrint('Searching HF models: $uri');
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final models = data
            .map((json) => HFModelInfo.fromJson(json as Map<String, dynamic>))
            .where((model) {
              // Filter by ONNX tag
              if (!model.isONNX) return false;

              // Filter by size if we can estimate it
              final size = model.estimatedSizeB;
              if (size != null && size > maxSizeB) return false;

              return true;
            })
            .toList();

        debugPrint('Found ${models.length} ONNX models (filtered by size <= ${maxSizeB}B)');
        return models;
      } else {
        debugPrint('HF API error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('Failed to search models: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching HF models: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

