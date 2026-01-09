import '../../../../core/services/llama_service.dart';
import '../../../../core/utils/chat_template.dart';
import '../../domain/entities/message.dart';

/// Abstract interface for LLM inference operations
abstract class LLMInferenceDataSource {
  /// Generate a response from the LLM based on conversation history
  /// 
  /// Returns a stream of response tokens for real-time streaming
  Stream<String> generateResponse({
    required List<Message> conversationHistory,
    bool includeSystemPrompt = true,
  });

  /// Generate a response from a single user message
  /// 
  /// Returns a stream of response tokens for real-time streaming
  Stream<String> generateFromPrompt(String userMessage);

  /// Check if the LLM is ready for inference
  bool isReady();
}

/// Implementation of LLM inference using llama.cpp
class LLMInferenceDataSourceImpl implements LLMInferenceDataSource {
  final LlamaService _llamaService;

  LLMInferenceDataSourceImpl(this._llamaService);

  @override
  Stream<String> generateResponse({
    required List<Message> conversationHistory,
    bool includeSystemPrompt = true,
  }) async* {
    if (!_llamaService.isInitialized) {
      throw StateError('LlamaService is not initialized');
    }

    // Format messages using ChatML template
    final prompt = ChatTemplate.formatMessages(
      messages: conversationHistory,
      includeSystemPrompt: includeSystemPrompt,
      addGenerationPrompt: true,
    );

    // Generate response stream
    await for (final token in _llamaService.generateStream(prompt)) {
      yield token;
    }
  }

  @override
  Stream<String> generateFromPrompt(String userMessage) async* {
    if (!_llamaService.isInitialized) {
      throw StateError('LlamaService is not initialized');
    }

    // Format single user message
    final prompt = ChatTemplate.formatUserMessage(userMessage);

    // Generate response stream
    await for (final token in _llamaService.generateStream(prompt)) {
      yield token;
    }
  }

  @override
  bool isReady() {
    return _llamaService.isInitialized;
  }
}

