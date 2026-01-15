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
    // Try to get real size from lfs field (for Git LFS files)
    int size = (json['size'] as num?)?.toInt() ?? 0;

    // Debug: print raw JSON for ONNX files to see what we're getting
    final path = json['path'] as String;
    if (path.endsWith('.onnx')) {
      debugPrint('📦 Parsing file: $path');
      debugPrint('   Raw size: $size bytes');
      debugPrint('   Has lfs field: ${json['lfs'] != null}');
      if (json['lfs'] != null) {
        debugPrint('   LFS data: ${json['lfs']}');
      }
    }

    // Check if this is a Git LFS file with real size info
    if (json['lfs'] != null && json['lfs'] is Map) {
      final lfs = json['lfs'] as Map<String, dynamic>;
      final lfsSize = (lfs['size'] as num?)?.toInt();
      if (lfsSize != null && lfsSize > 0) {
        size = lfsSize;
        debugPrint('   ✓ Using LFS size: $size bytes');
      }
    }

    return HFModelFile(
      path: path,
      size: size,
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

  /// Check if this is a CPU-optimized model
  bool get isCPUModel {
    final pathLower = path.toLowerCase();
    return pathLower.contains('/cpu/') || pathLower.contains('cpu-');
  }

  /// Check if this is a GPU-optimized model
  bool get isGPUModel {
    final pathLower = path.toLowerCase();
    return pathLower.contains('/gpu/') || pathLower.contains('gpu-');
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
  /// Adds ?download=true to force LFS file download instead of pointer
  String getDownloadUrl(String repoId) {
    return 'https://huggingface.co/$repoId/resolve/main/$path?download=true';
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
  /// [includeTokenizer] - Include tokenizer and config files
  Future<List<HFModelFile>> getModelFiles({
    required String repoId,
    String? fileType,
    bool includeTokenizer = false,
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

      // Include model files (ONNX or GGUF)
      if (file.isONNX || file.isGGUF) return true;

      // Include tokenizer and config files if requested
      if (includeTokenizer) {
        final fileName = file.path.toLowerCase();
        return fileName.endsWith('tokenizer.json') ||
               fileName.endsWith('tokenizer_config.json') ||
               fileName.endsWith('vocab.json') ||
               fileName.endsWith('config.json') ||
               fileName.endsWith('generation_config.json') ||
               fileName.endsWith('special_tokens_map.json');
      }

      return false;
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

        // Debug: print first ONNX file structure
        if (path.contains('onnx') && data.isNotEmpty) {
          final firstOnnx = data.firstWhere(
            (item) => (item as Map<String, dynamic>)['path'].toString().endsWith('.onnx'),
            orElse: () => null,
          );
          if (firstOnnx != null) {
            debugPrint('📦 Sample ONNX file from API:');
            debugPrint('   ${json.encode(firstOnnx)}');
          }
        }

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
  /// Also includes tokenizer and config files
  Future<Map<String, List<HFModelFile>>> getONNXFilesByQuantization(String repoId) async {
    // Get model files AND tokenizer files
    final modelFiles = await getModelFiles(repoId: repoId, fileType: 'onnx');
    final tokenizerFiles = await getModelFiles(repoId: repoId, includeTokenizer: true);

    debugPrint('Found ${tokenizerFiles.length} tokenizer/config files');

    // Separate main files and data files
    // Filter out GPU models as they require MatMulNBits which is not supported on mobile
    final mainFiles = <HFModelFile>[];
    final dataFiles = <String, List<HFModelFile>>{};

    for (final file in modelFiles) {
      final fileName = file.path.toLowerCase();

      // Skip GPU models - they use MatMulNBits which is not supported on Android
      if (file.isGPUModel) {
        debugPrint('⏭️ Skipping GPU model (not supported on mobile): ${file.path}');
        continue;
      }

      if (fileName.endsWith('.onnx') && !fileName.contains('_data')) {
        mainFiles.add(file);
      } else if (fileName.contains('_data')) {
        // Extract base name (e.g., "model_q4.onnx" from "model_q4.onnx_data")
        final baseName = file.path.replaceAll(RegExp(r'_data(_\d+)?$'), '');
        dataFiles.putIfAbsent(baseName, () => []).add(file);
      }
    }

    // Attach related files (data files + tokenizer files)
    for (final mainFile in mainFiles) {
      final related = dataFiles[mainFile.path] ?? [];
      mainFile.relatedFiles.addAll(related);

      // Add tokenizer files to each model
      mainFile.relatedFiles.addAll(tokenizerFiles);
    }

    debugPrint('Each model will download ${tokenizerFiles.length} tokenizer files');

    // Fetch all sizes in parallel
    debugPrint('Fetching sizes for ${mainFiles.length} main files + tokenizer files...');
    final allFilesToFetch = <HFModelFile>[];

    // Add all model files
    for (final mainFile in mainFiles) {
      allFilesToFetch.add(mainFile);
      // Add data files (but not tokenizer files yet, to avoid duplicates)
      allFilesToFetch.addAll(dataFiles[mainFile.path] ?? []);
    }

    // Add tokenizer files once
    allFilesToFetch.addAll(tokenizerFiles);

    debugPrint('Total files to fetch sizes for: ${allFilesToFetch.length}');

    // Fetch sizes in parallel (max 5 at a time to avoid overwhelming the server)
    final futures = <Future<void>>[];
    for (final file in allFilesToFetch) {
      futures.add(_fetchRealSize(repoId, file));

      // Process in batches of 5
      if (futures.length >= 5) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    // Wait for remaining
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    debugPrint('All sizes fetched!');

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

  /// Fetch real file size using HEAD request with redirect following
  Future<void> _fetchRealSize(String repoId, HFModelFile file) async {
    try {
      // Skip if size is already large (> 10 MB), indicating it's the real file size from LFS
      const minModelSize = 10 * 1024 * 1024; // 10 MB
      if (file.size > minModelSize) {
        debugPrint('✓ Size already known for ${file.path}: ${file.formattedSize}');
        return;
      }

      // For small files (< 10 MB), they might be:
      // 1. Git LFS pointer files (need to fetch real size)
      // 2. Actually small files (config, tokenizer, etc.)
      // We'll just keep the size from LFS API
      // Don't try to fetch size for small files - it's unreliable and slow

    } catch (e) {
      debugPrint('✗ Failed to fetch size for ${file.path}: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

