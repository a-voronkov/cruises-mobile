import '../../../../core/services/ai_service.dart';
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

/// Implementation of LLM inference using HuggingFace Inference API
class LLMInferenceDataSourceImpl implements LLMInferenceDataSource {
  final AIService _aiService;

  LLMInferenceDataSourceImpl(this._aiService);

  @override
  Stream<String> generateResponse({
    required List<Message> conversationHistory,
    bool includeSystemPrompt = true,
  }) async* {
    // Convert conversation history to messages format
    final messages = conversationHistory.map((msg) {
      return {
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      };
    }).toList();

    // Add system message if requested
    if (includeSystemPrompt) {
      messages.insert(0, {
        'role': 'system',
        'content': 'You are a helpful travel assistant. You help users plan their cruise vacations and travel itineraries.',
      });
    }

    // Generate response stream
    await for (final token in _aiService.generateStream(messages: messages)) {
      yield token;
    }
  }

  @override
  Stream<String> generateFromPrompt(String userMessage) async* {
    final messages = [
      {
        'role': 'system',
        'content': 'You are a helpful travel assistant.',
      },
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    // Generate response stream
    await for (final token in _aiService.generateStream(messages: messages)) {
      yield token;
    }
  }

  @override
  bool isReady() {
    // AIService is always ready (cloud-based)
    return true;
  }
}

