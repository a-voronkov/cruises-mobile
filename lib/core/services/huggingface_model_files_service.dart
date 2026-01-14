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

    // Attach related files
    for (final mainFile in mainFiles) {
      final related = dataFiles[mainFile.path] ?? [];
      mainFile.relatedFiles.addAll(related);
    }

    // Fetch all sizes in parallel
    debugPrint('Fetching sizes for ${mainFiles.length} main files...');
    final allFilesToFetch = <HFModelFile>[];
    for (final mainFile in mainFiles) {
      allFilesToFetch.add(mainFile);
      allFilesToFetch.addAll(mainFile.relatedFiles);
    }

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
      // For ONNX/GGUF files, the size from API is often just the Git LFS pointer size
      // We need to fetch the real size via HEAD request
      // Skip only if size is already large (> 10 MB), indicating it's the real file size
      const minModelSize = 10 * 1024 * 1024; // 10 MB
      if (file.size > minModelSize) {
        debugPrint('✓ Size already known for ${file.path}: ${file.formattedSize}');
        return;
      }

      final url = file.getDownloadUrl(repoId);
      final uri = Uri.parse(url);

      final headers = <String, String>{
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };

      debugPrint('→ Fetching size for ${file.path}...');

      // Try HEAD request first (follows redirects automatically)
      try {
        final request = http.Request('HEAD', uri);
        request.headers.addAll(headers);
        request.followRedirects = true;
        request.maxRedirects = 5;

        final streamedResponse = await _client.send(request);

        debugPrint('  HEAD response: ${streamedResponse.statusCode}');

        if (streamedResponse.statusCode == 200) {
          // For Git LFS files, HuggingFace returns X-Linked-Size header with real file size
          final linkedSize = streamedResponse.headers['x-linked-size'];
          if (linkedSize != null) {
            final size = int.tryParse(linkedSize);
            if (size != null && size > 0) {
              file.size = size;
              debugPrint('✓ Fetched size via X-Linked-Size for ${file.path}: ${file.formattedSize} ($size bytes)');
              return;
            }
          }

          // Check Content-Length
          final contentLength = streamedResponse.headers['content-length'];
          if (contentLength != null) {
            final size = int.tryParse(contentLength);
            if (size != null && size > 0) {
              // If size is suspiciously small for a model file (< 1 MB), it's likely a Git LFS pointer
              // Try the fallback method to get the real size
              const minRealFileSize = 1024 * 1024; // 1 MB
              if (size < minRealFileSize && (file.isONNX || file.isGGUF)) {
                debugPrint('  ⚠ Size too small ($size bytes), likely LFS pointer - trying fallback...');
                // Don't return, fall through to fallback method
              } else {
                file.size = size;
                debugPrint('✓ Fetched size via Content-Length for ${file.path}: ${file.formattedSize} ($size bytes)');
                return;
              }
            }
          }

          if (linkedSize == null && contentLength == null) {
            debugPrint('  ⚠ No size headers found (X-Linked-Size or Content-Length)');
          }
        }
      } catch (e) {
        debugPrint('  ✗ HEAD request failed: $e');
      }

      // Fallback: Try to get size from file metadata API
      try {
        debugPrint('  Trying metadata API...');
        final metaUri = Uri.parse('https://huggingface.co/$repoId/resolve/main/${file.path}?download=false');
        final metaRequest = http.Request('HEAD', metaUri);
        metaRequest.headers.addAll(headers);
        metaRequest.followRedirects = false; // Don't follow redirects

        final metaResponse = await _client.send(metaRequest);
        debugPrint('  Metadata response: ${metaResponse.statusCode}');

        if (metaResponse.statusCode == 302 || metaResponse.statusCode == 301) {
          // Follow redirect manually to get final URL
          final location = metaResponse.headers['location'];
          if (location != null) {
            debugPrint('  Redirect to: $location');
            final finalUri = Uri.parse(location);
            final finalRequest = http.Request('HEAD', finalUri);
            final finalResponse = await _client.send(finalRequest);

            debugPrint('  Final response: ${finalResponse.statusCode}');
            final contentLength = finalResponse.headers['content-length'];
            debugPrint('  Final Content-Length: $contentLength');

            if (contentLength != null) {
              final size = int.tryParse(contentLength);
              if (size != null && size > 0) {
                file.size = size;
                debugPrint('✓ Fetched size via redirect for ${file.path}: ${file.formattedSize}');
                return;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('  ✗ Metadata API failed: $e');
      }

      debugPrint('⚠ Could not fetch size for ${file.path} - will show as Unknown');
    } catch (e) {
      debugPrint('✗ Failed to fetch size for ${file.path}: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

