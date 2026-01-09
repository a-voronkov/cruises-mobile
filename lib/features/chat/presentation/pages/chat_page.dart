import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/message_list.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_app_bar.dart';

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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: MessageList(
              conversationId: widget.conversationId,
              scrollController: _scrollController,
            ),
          ),

          // Input area
          ChatInput(
            controller: _messageController,
            onSend: (message, attachments) {
              // TODO: Implement send message
              _messageController.clear();
              _scrollToBottom();
            },
            onVoiceInput: () {
              // TODO: Implement voice input
            },
          ),
        ],
      ),
    );
  }
}

