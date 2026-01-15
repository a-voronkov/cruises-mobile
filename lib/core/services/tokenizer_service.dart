import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Simple tokenizer service for ONNX models
///
/// Reads tokenizer.json and provides basic tokenization functionality
class TokenizerService {
  Map<String, dynamic>? _tokenizerConfig;
  Map<String, int>? _vocab;
  Map<int, String>? _reverseVocab;
  
  bool _isInitialized = false;
  
  /// Initialize tokenizer from files
  Future<bool> initialize(String modelDir) async {
    try {
      debugPrint('TokenizerService: Initializing from $modelDir');
      
      // Try to load tokenizer.json
      final tokenizerFile = File('$modelDir/tokenizer.json');
      if (await tokenizerFile.exists()) {
        final content = await tokenizerFile.readAsString();
        _tokenizerConfig = json.decode(content) as Map<String, dynamic>;

        // Extract vocabulary
        final model = _tokenizerConfig!['model'] as Map<String, dynamic>?;
        if (model != null && model['vocab'] != null) {
          final vocabData = model['vocab'];

          // Handle different vocab formats
          if (vocabData is Map) {
            _vocab = Map<String, int>.from(vocabData);
            _reverseVocab = _vocab!.map((key, value) => MapEntry(value, key));
            debugPrint('TokenizerService: Loaded ${_vocab!.length} tokens from tokenizer.json (Map format)');
          } else if (vocabData is List) {
            // Some models use array format: ["token1", "token2", ...]
            _vocab = {};
            for (var i = 0; i < vocabData.length; i++) {
              final item = vocabData[i];
              if (item is String) {
                _vocab![item] = i;
              } else if (item is List && item.isNotEmpty) {
                // Some tokenizers use [token, id] format
                _vocab![item[0].toString()] = item.length > 1 ? item[1] as int : i;
              } else {
                // Fallback: convert to string
                _vocab![item.toString()] = i;
              }
            }
            _reverseVocab = _vocab!.map((key, value) => MapEntry(value, key));
            debugPrint('TokenizerService: Loaded ${_vocab!.length} tokens from tokenizer.json (List format)');
          }
        }
      }
      
      // Try to load vocab.json as fallback
      if (_vocab == null) {
        final vocabFile = File('$modelDir/vocab.json');
        if (await vocabFile.exists()) {
          final content = await vocabFile.readAsString();
          final vocabData = json.decode(content);

          // Handle different vocab formats
          if (vocabData is Map) {
            _vocab = Map<String, int>.from(vocabData);
            _reverseVocab = _vocab!.map((key, value) => MapEntry(value, key));
            debugPrint('TokenizerService: Loaded ${_vocab!.length} tokens from vocab.json (Map format)');
          } else if (vocabData is List) {
            // Some models use array format: ["token1", "token2", ...]
            _vocab = {};
            for (var i = 0; i < vocabData.length; i++) {
              final item = vocabData[i];
              if (item is String) {
                _vocab![item] = i;
              } else if (item is List && item.isNotEmpty) {
                // Some tokenizers use [token, id] format
                _vocab![item[0].toString()] = item.length > 1 ? item[1] as int : i;
              } else {
                // Fallback: convert to string
                _vocab![item.toString()] = i;
              }
            }
            _reverseVocab = _vocab!.map((key, value) => MapEntry(value, key));
            debugPrint('TokenizerService: Loaded ${_vocab!.length} tokens from vocab.json (List format)');
          }
        }
      }
      
      if (_vocab == null) {
        debugPrint('TokenizerService: No vocabulary found');
        return false;
      }
      
      _isInitialized = true;
      debugPrint('TokenizerService: Initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('TokenizerService: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Encode text to token IDs (simplified implementation)
  List<int> encode(String text) {
    if (!_isInitialized || _vocab == null) {
      throw StateError('Tokenizer not initialized');
    }
    
    // Very simple word-based tokenization
    // Real implementation would use BPE or WordPiece
    final tokens = <int>[];
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    
    for (final word in words) {
      if (_vocab!.containsKey(word)) {
        tokens.add(_vocab![word]!);
      } else {
        // Use unknown token
        final unkToken = _vocab!['<unk>'] ?? _vocab!['[UNK]'] ?? 0;
        tokens.add(unkToken);
      }
    }
    
    return tokens;
  }
  
  /// Decode token IDs to text
  String decode(List<int> tokenIds) {
    if (!_isInitialized || _reverseVocab == null) {
      throw StateError('Tokenizer not initialized');
    }
    
    final words = <String>[];
    for (final id in tokenIds) {
      if (_reverseVocab!.containsKey(id)) {
        words.add(_reverseVocab![id]!);
      }
    }
    
    return words.join(' ');
  }
  
  /// Get special token IDs
  Map<String, int> getSpecialTokens() {
    if (!_isInitialized || _vocab == null) {
      return {};
    }
    
    final special = <String, int>{};
    
    // Common special tokens
    final specialTokenNames = [
      '<s>', '</s>', '<unk>', '[UNK]', '<pad>', '[PAD]',
      '<bos>', '<eos>', '<|endoftext|>', '<|im_start|>', '<|im_end|>',
    ];
    
    for (final name in specialTokenNames) {
      if (_vocab!.containsKey(name)) {
        special[name] = _vocab![name]!;
      }
    }
    
    return special;
  }
  
  /// Get vocabulary size
  int get vocabSize => _vocab?.length ?? 0;
  
  /// Check if initialized
  bool get isInitialized => _isInitialized;
  
  /// Dispose resources
  void dispose() {
    _tokenizerConfig = null;
    _vocab = null;
    _reverseVocab = null;
    _isInitialized = false;
    debugPrint('TokenizerService: Disposed');
  }
}

