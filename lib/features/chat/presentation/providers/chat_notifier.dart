import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/ai_service_provider.dart';
import '../../../../core/utils/chat_template.dart';
import '../../domain/entities/message.dart';
import '../../data/datasources/chat_local_datasource_provider.dart';
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
  bool _isInitialized = false;

  ChatNotifier(this._ref)
      : super(ChatState(conversationId: _uuid.v4())) {
    _initialize();
  }

  /// Initialize the chat - load existing messages or create new conversation
  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final dataSource = _ref.read(chatLocalDataSourceProvider);

    // Try to load existing messages for this conversation
    final messages = await dataSource.getMessages(state.conversationId);

    if (messages.isEmpty) {
      // New conversation - add welcome message and save
      await _createNewConversation();
    } else {
      state = state.copyWith(messages: messages);
    }
  }

  /// Create a new conversation with welcome message
  Future<void> _createNewConversation() async {
    final dataSource = _ref.read(chatLocalDataSourceProvider);

    // Create conversation in storage
    await dataSource.createConversation(
      id: state.conversationId,
      title: 'Cruise Chat',
    );

    // Create and save welcome message
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

    await dataSource.saveMessage(welcomeMessage);
    state = state.copyWith(messages: [welcomeMessage]);
  }

  /// Load an existing conversation
  Future<void> loadConversation(String conversationId) async {
    final dataSource = _ref.read(chatLocalDataSourceProvider);
    final messages = await dataSource.getMessages(conversationId);

    state = ChatState(
      conversationId: conversationId,
      messages: messages,
    );
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

    // Save user message to storage
    final dataSource = _ref.read(chatLocalDataSourceProvider);
    await dataSource.saveMessage(userMessage);

    try {
      // Get AI service
      final aiService = _ref.read(aiServiceProvider);

      // Get cruise context for system prompt
      final cruiseContext = _ref.read(cruiseContextProvider);

      // Build messages for LLM (excluding welcome message for context)
      final messagesForLLM = state.messages
          .where((m) => m.role != MessageRole.system)
          .toList();

      // Convert to messages format for AI service
      final messages = messagesForLLM.map((msg) {
        return {
          'role': msg.role == MessageRole.user ? 'user' : 'assistant',
          'content': msg.content,
        };
      }).toList();

      // Add system message with cruise context
      final systemContent = cruiseContext != null
          ? 'You are a helpful travel assistant. ${ChatTemplate.formatCruiseContext(cruiseContext)}'
          : 'You are a helpful travel assistant.';

      messages.insert(0, {
        'role': 'system',
        'content': systemContent,
      });

      // Generate response stream
      final responseBuffer = StringBuffer();

      await for (final token in aiService.generateStream(messages: messages)) {
        responseBuffer.write(token);
        state = state.copyWith(currentResponse: responseBuffer.toString());
      }

      // Extract clean response
      final finalResponse =
          ChatTemplate.extractResponse(responseBuffer.toString());

      // Add assistant message
      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: state.conversationId,
        content: finalResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      // Save assistant message to storage
      await dataSource.saveMessage(assistantMessage);

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isGenerating: false,
        currentResponse: '',
      );
    } catch (e) {
      debugPrint('Error generating response: $e');
      state = state.copyWith(
        isGenerating: false,
        error: 'Error: $e',
      );
    }
  }

  /// Clear chat and start new conversation
  Future<void> clearChat() async {
    _isInitialized = false;
    state = ChatState(conversationId: _uuid.v4());
    await _createNewConversation();
  }
}

/// Provider for chat state
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

