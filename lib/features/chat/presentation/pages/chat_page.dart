import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/message_bubble.dart';
import '../providers/chat_notifier.dart';
import '../../domain/entities/message.dart';
import '../../../../core/services/ai_service_provider.dart';

/// Main chat page with ChatGPT-like interface
class ChatPage extends ConsumerStatefulWidget {
  final String? conversationId;

  const ChatPage({
    super.key,
    this.conversationId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-initialize model when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeModelIfNeeded();
    });
  }

  void _initializeModelIfNeeded() {
    // Cloud-based AI service is always ready, no initialization needed
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final aiServiceState = ref.watch(aiServiceStateProvider);

    // Auto-scroll when messages change
    ref.listen(chatNotifierProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.currentResponse != next.currentResponse) {
        _scrollToBottom();
      }
    });

    // Check if model is ready for chat (cloud service is always ready)
    final bool canChat = aiServiceState.isReady && !chatState.isGenerating;

    return Scaffold(
      appBar: const ChatAppBar(),
      body: Column(
        children: [
          // Error banner
          if (chatState.error != null)
            _buildErrorBanner(chatState.error!),

          // Messages list
          Expanded(
            child: _buildMessageList(chatState),
          ),

          // Input area with SafeArea for system navigation bar
          SafeArea(
            top: false,
            child: ChatInput(
              controller: _messageController,
              enabled: canChat,
              onSend: (message, attachments) {
                ref.read(chatNotifierProvider.notifier).sendMessage(message);
                _messageController.clear();
              },
              onVoiceInput: () {
                // TODO: Implement voice input
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusBanner(AIServiceState aiServiceState) {
    final theme = Theme.of(context);

    if (aiServiceState.error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: theme.colorScheme.errorContainer,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                aiServiceState.error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Preparing AI assistant...'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.warning, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length + (chatState.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        // Show streaming response as last item
        if (index == chatState.messages.length && chatState.isGenerating) {
          return MessageBubble(
            content: chatState.currentResponse.isEmpty
                ? '...'
                : chatState.currentResponse,
            isUser: false,
            isStreaming: true,
          );
        }

        final message = chatState.messages[index];
        return MessageBubble(
          content: message.content,
          isUser: message.role == MessageRole.user,
          timestamp: message.timestamp,
        );
      },
    );
  }
}

