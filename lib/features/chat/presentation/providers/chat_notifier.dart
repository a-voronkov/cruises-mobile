import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/llama_service_provider.dart';
import '../../../../core/utils/chat_template.dart';
import '../../domain/entities/message.dart';
import 'cruise_context_provider.dart';

/// State for the chat
class ChatState {
  final List<Message> messages;
  final bool isGenerating;
  final String currentResponse;
  final String? error;
  final String conversationId;

  const ChatState({
    required this.conversationId,
    this.messages = const [],
    this.isGenerating = false,
    this.currentResponse = '',
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isGenerating,
    String? currentResponse,
    String? error,
    String? conversationId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      currentResponse: currentResponse ?? this.currentResponse,
      error: error,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

/// Notifier for managing chat state and LLM interactions
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  static const _uuid = Uuid();

  ChatNotifier(this._ref)
      : super(ChatState(conversationId: _uuid.v4())) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = Message(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      content: '''Hello! I'm your personal cruise assistant and I'll work even at sea, without internet.

Together we can:
• Plan your cruise activities
• Organize shore excursions
• Answer questions about the ship and ports
• And much more!

How can I help you today?''',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [welcomeMessage]);
  }

  /// Send a message and get LLM response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isGenerating) return;

    // Add user message
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isGenerating: true,
      currentResponse: '',
      error: null,
    );

    try {
      // Check if LLM is initialized
      final llamaService = _ref.read(llamaServiceProvider);
      if (!llamaService.isInitialized) {
        throw StateError('AI model is not initialized');
      }

      // Get cruise context for system prompt
      final cruiseContext = _ref.read(cruiseContextProvider);

      // Build messages for LLM (excluding welcome message for context)
      final messagesForLLM = state.messages
          .where((m) => m.role != MessageRole.system)
          .toList();

      // Format prompt with cruise context
      final prompt = ChatTemplate.formatMessagesWithContext(
        messages: messagesForLLM,
        cruiseContext: cruiseContext,
      );

      // Generate response stream
      final responseBuffer = StringBuffer();

      await for (final token in llamaService.generateStream(prompt)) {
        responseBuffer.write(token);
        state = state.copyWith(currentResponse: responseBuffer.toString());
      }

      // Extract clean response
      final finalResponse = ChatTemplate.extractResponse(responseBuffer.toString());

      // Add assistant message
      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: state.conversationId,
        content: finalResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isGenerating: false,
        currentResponse: '',
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Error: $e',
      );
    }
  }

  /// Clear chat and start new conversation
  void clearChat() {
    state = ChatState(conversationId: _uuid.v4());
    _addWelcomeMessage();
  }
}

/// Provider for chat state
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

