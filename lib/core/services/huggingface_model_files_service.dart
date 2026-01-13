import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Information about a model file on HuggingFace
class HFModelFile {
  final String path;
  int size; // Mutable to allow updating after fetching real size
  final String? oid; // Git LFS object ID
  final String type; // 'file' or 'directory'
  final List<HFModelFile> relatedFiles; // For _data files

  HFModelFile({
    required this.path,
    required this.size,
    this.oid,
    required this.type,
    List<HFModelFile>? relatedFiles,
  }) : relatedFiles = relatedFiles ?? [];

  factory HFModelFile.fromJson(Map<String, dynamic> json) {
    return HFModelFile(
      path: json['path'] as String,
      size: (json['size'] as num?)?.toInt() ?? 0,
      oid: json['oid'] as String?,
      type: json['type'] as String? ?? 'file',
    );
  }

  /// Get total size including related files
  int get totalSize {
    int total = size;
    for (final related in relatedFiles) {
      total += related.size;
    }
    return total;
  }

  /// Get quantization type from filename (e.g., "int8", "fp16", "q4")
  String? get quantization {
    final fileName = path.toLowerCase();

    // ONNX quantization patterns
    if (fileName.contains('_q8') || fileName.contains('q8.onnx')) return 'Q8';
    if (fileName.contains('_q4') || fileName.contains('q4.onnx')) return 'Q4';
    if (fileName.contains('_int8') || fileName.contains('int8')) return 'INT8';
    if (fileName.contains('_int4') || fileName.contains('int4')) return 'INT4';
    if (fileName.contains('_fp16') || fileName.contains('fp16')) return 'FP16';
    if (fileName.contains('_fp32') || fileName.contains('fp32')) return 'FP32';

    // GGUF quantization patterns
    if (fileName.contains('q4_k_m')) return 'Q4_K_M';
    if (fileName.contains('q5_k_m')) return 'Q5_K_M';
    if (fileName.contains('q6_k')) return 'Q6_K';
    if (fileName.contains('q8_0')) return 'Q8_0';
    if (fileName.contains('f16')) return 'F16';

    // Default for ONNX files without explicit quantization
    if (fileName.endsWith('.onnx') && !fileName.contains('_data')) {
      return 'Default';
    }

    return null;
  }

  /// Check if this is an ONNX model file
  bool get isONNX => path.toLowerCase().endsWith('.onnx');

  /// Check if this is a GGUF model file
  bool get isGGUF => path.toLowerCase().endsWith('.gguf');

  /// Format size in human readable format
  String get formattedSize {
    final bytes = totalSize;
    if (bytes == 0) return 'Unknown size';

    final mb = bytes / (1024 * 1024);
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

  /// Get list of files for a model repository (recursively)
  ///
  /// [repoId] - HuggingFace repository ID (e.g., "meta-llama/Llama-3.2-1B-Instruct")
  /// [fileType] - Filter by file extension (e.g., "onnx", "gguf")
  Future<List<HFModelFile>> getModelFiles({
    required String repoId,
    String? fileType,
  }) async {
    final allFiles = <HFModelFile>[];

    // Recursively fetch files from all directories
    await _fetchFilesRecursive(repoId, '', allFiles);

    // Filter files
    final filteredFiles = allFiles.where((file) {
      // Filter by file type if specified
      if (fileType != null) {
        final ext = file.path.toLowerCase().split('.').last;
        if (ext != fileType.toLowerCase()) return false;
      }

      // Only include model files (ONNX or GGUF)
      return file.isONNX || file.isGGUF;
    }).toList();

    debugPrint('Found ${filteredFiles.length} model files (total: ${allFiles.length})');
    return filteredFiles;
  }

  /// Recursively fetch files from a directory
  Future<void> _fetchFilesRecursive(
    String repoId,
    String path,
    List<HFModelFile> accumulator,
  ) async {
    try {
      final uri = path.isEmpty
          ? Uri.parse('https://huggingface.co/api/models/$repoId/tree/main')
          : Uri.parse('https://huggingface.co/api/models/$repoId/tree/main/$path');

      final headers = <String, String>{
        'Accept': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };

      debugPrint('Fetching files from: $uri');
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;

        for (final item in data) {
          final file = HFModelFile.fromJson(item as Map<String, dynamic>);

          if (file.type == 'directory') {
            // Recursively fetch files from subdirectory
            await _fetchFilesRecursive(repoId, file.path, accumulator);
          } else {
            // Add file to accumulator
            accumulator.add(file);
          }
        }
      } else if (response.statusCode == 404) {
        debugPrint('Path not found: $path');
      } else {
        debugPrint('HF API error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching files from $path: $e');
    }
  }

  /// Get ONNX files grouped by quantization
  ///
  /// Groups main .onnx files with their _data files and fetches real sizes
  Future<Map<String, List<HFModelFile>>> getONNXFilesByQuantization(String repoId) async {
    final allFiles = await getModelFiles(repoId: repoId, fileType: 'onnx');

    // Separate main files and data files
    final mainFiles = <HFModelFile>[];
    final dataFiles = <String, List<HFModelFile>>{};

    for (final file in allFiles) {
      final fileName = file.path.toLowerCase();
      if (fileName.endsWith('.onnx') && !fileName.contains('_data')) {
        mainFiles.add(file);
      } else if (fileName.contains('_data')) {
        // Extract base name (e.g., "model_q4.onnx" from "model_q4.onnx_data")
        final baseName = file.path.replaceAll(RegExp(r'_data(_\d+)?$'), '');
        dataFiles.putIfAbsent(baseName, () => []).add(file);
      }
    }

    // Attach related files and fetch real sizes
    for (final mainFile in mainFiles) {
      final related = dataFiles[mainFile.path] ?? [];
      mainFile.relatedFiles.addAll(related);

      // Fetch real size for main file
      await _fetchRealSize(repoId, mainFile);

      // Fetch real sizes for related files
      for (final relatedFile in related) {
        await _fetchRealSize(repoId, relatedFile);
      }
    }

    // Group by quantization
    final grouped = <String, List<HFModelFile>>{};
    for (final file in mainFiles) {
      final quant = file.quantization ?? 'Unknown';
      grouped.putIfAbsent(quant, () => []).add(file);
    }

    // Sort quantizations by quality (higher quality first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final order = ['FP32', 'FP16', 'Q8', 'INT8', 'Q4', 'INT4', 'Default', 'Unknown'];
        final aIndex = order.indexOf(a.key);
        final bIndex = order.indexOf(b.key);
        if (aIndex == -1 && bIndex == -1) return a.key.compareTo(b.key);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    return Map.fromEntries(sortedEntries);
  }

  /// Fetch real file size using HEAD request
  Future<void> _fetchRealSize(String repoId, HFModelFile file) async {
    try {
      final url = file.getDownloadUrl(repoId);
      final uri = Uri.parse(url);

      final headers = <String, String>{
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };

      final response = await _client.head(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          file.size = int.tryParse(contentLength) ?? file.size;
          debugPrint('Fetched size for ${file.path}: ${file.formattedSize}');
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch size for ${file.path}: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

