import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'message_bubble.dart';
import '../../domain/entities/message.dart';

/// List of messages in the chat
class MessageList extends ConsumerWidget {
  final String? conversationId;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    this.conversationId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get messages from provider
    // For now, show placeholder
    final messages = _getDemoMessages();

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your travel plans',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  // Demo messages for UI testing
  List<Message> _getDemoMessages() {
    return [
      Message(
        id: '1',
        conversationId: 'demo',
        content: 'Hello! I need help planning a cruise vacation.',
        role: MessageRole.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: '2',
        conversationId: 'demo',
        content:
            'Hello! I\'d be happy to help you plan your cruise vacation. To provide you with the best recommendations, I\'d like to know:\n\n1. What\'s your preferred destination or region?\n2. How long would you like the cruise to be?\n3. What\'s your approximate budget?\n4. Are you traveling alone, with a partner, or with family?\n5. What time of year are you planning to travel?',
        role: MessageRole.assistant,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      Message(
        id: '3',
        conversationId: 'demo',
        content:
            'I\'m thinking about the Mediterranean, maybe 7-10 days, traveling with my partner in September.',
        role: MessageRole.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }
}

