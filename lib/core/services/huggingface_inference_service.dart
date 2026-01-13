import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for HuggingFace Inference API
/// 
/// Provides text generation capabilities using HuggingFace's hosted models.
/// Supports streaming responses for real-time text generation.
class HuggingFaceInferenceService {
  final String _apiKey;
  final http.Client _client;
  
  static const String _baseUrl = 'https://api-inference.huggingface.co';
  
  HuggingFaceInferenceService({
    required String apiKey,
    http.Client? client,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client();

  /// Generate text using a HuggingFace model
  /// 
  /// [modelId] - Model ID (e.g., "meta-llama/Llama-3.2-1B-Instruct")
  /// [prompt] - Input prompt
  /// [maxTokens] - Maximum number of tokens to generate
  /// [temperature] - Sampling temperature (0.0 to 1.0)
  /// [topP] - Nucleus sampling parameter
  /// [stream] - Whether to stream the response
  Future<String> generate({
    required String modelId,
    required String prompt,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    bool stream = false,
  }) async {
    if (stream) {
      // For streaming, collect all chunks
      final buffer = StringBuffer();
      await for (final chunk in generateStream(
        modelId: modelId,
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
      )) {
        buffer.write(chunk);
      }
      return buffer.toString();
    }

    try {
      final url = Uri.parse('$_baseUrl/models/$modelId');
      
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': maxTokens,
          'temperature': temperature,
          'top_p': topP,
          'return_full_text': false,
        },
      });

      final response = await _client.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final List<dynamic> result = json.decode(response.body);
        if (result.isNotEmpty && result[0] is Map) {
          return result[0]['generated_text'] as String? ?? '';
        }
        return '';
      } else {
        debugPrint('HuggingFaceInferenceService: Error ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('Failed to generate text: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('HuggingFaceInferenceService: Error generating text: $e');
      rethrow;
    }
  }

  /// Generate text with streaming response
  /// 
  /// Returns a stream of text chunks as they are generated.
  Stream<String> generateStream({
    required String modelId,
    required String prompt,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
  }) async* {
    try {
      final url = Uri.parse('$_baseUrl/models/$modelId');
      
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': maxTokens,
          'temperature': temperature,
          'top_p': topP,
          'return_full_text': false,
        },
        'options': {
          'use_cache': false,
        },
        'stream': true,
      });

      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // HuggingFace streams in SSE format: "data: {...}\n\n"
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
                try {
                  final data = json.decode(jsonStr);
                  if (data is Map && data.containsKey('token')) {
                    final token = data['token'];
                    if (token is Map && token.containsKey('text')) {
                      yield token['text'] as String;
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing SSE chunk: $e');
                }
              }
            }
          }
        }
      } else {
        throw Exception('Failed to generate text: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('HuggingFaceInferenceService: Error in stream: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

