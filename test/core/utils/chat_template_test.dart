import 'package:flutter_test/flutter_test.dart';
import 'package:cruises_mobile/core/utils/chat_template.dart';
import 'package:cruises_mobile/features/chat/domain/entities/message.dart';

void main() {
  group('ChatTemplate', () {
    test('formatUserMessage creates correct ChatML format', () {
      final prompt = ChatTemplate.formatUserMessage('Hello, how are you?');

      expect(prompt, contains('<|startoftext|>'));
      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('<|im_end|>'));
      expect(prompt, contains('<|im_start|>user'));
      expect(prompt, contains('Hello, how are you?'));
      expect(prompt, contains('<|im_start|>assistant'));
    });

    test('formatMessages with single user message', () {
      final messages = [
        Message(
          id: '1',
          conversationId: 'test',
          content: 'What is a cruise?',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final prompt = ChatTemplate.formatMessages(messages: messages);

      expect(prompt, contains('<|startoftext|>'));
      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('travel assistant'));
      expect(prompt, contains('<|im_start|>user'));
      expect(prompt, contains('What is a cruise?'));
      expect(prompt, endsWith('<|im_start|>assistant\n'));
    });

    test('formatMessages with conversation history', () {
      final messages = [
        Message(
          id: '1',
          conversationId: 'test',
          content: 'Hello',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
        Message(
          id: '2',
          conversationId: 'test',
          content: 'Hi! How can I help you plan your cruise?',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
        Message(
          id: '3',
          conversationId: 'test',
          content: 'I want to visit the Mediterranean',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final prompt = ChatTemplate.formatMessages(messages: messages);

      expect(prompt, contains('<|im_start|>user\nHello<|im_end|>'));
      expect(
        prompt,
        contains(
          '<|im_start|>assistant\nHi! How can I help you plan your cruise?<|im_end|>',
        ),
      );
      expect(
        prompt,
        contains('<|im_start|>user\nI want to visit the Mediterranean<|im_end|>'),
      );
    });

    test('formatMessages without system prompt', () {
      final messages = [
        Message(
          id: '1',
          conversationId: 'test',
          content: 'Test message',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final prompt = ChatTemplate.formatMessages(
        messages: messages,
        includeSystemPrompt: false,
      );

      expect(prompt, contains('<|startoftext|>'));
      expect(prompt, isNot(contains('<|im_start|>system')));
      expect(prompt, contains('<|im_start|>user'));
    });

    test('formatMessages without generation prompt', () {
      final messages = [
        Message(
          id: '1',
          conversationId: 'test',
          content: 'Test',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final prompt = ChatTemplate.formatMessages(
        messages: messages,
        addGenerationPrompt: false,
      );

      expect(prompt, isNot(endsWith('<|im_start|>assistant\n')));
      expect(prompt, endsWith('<|im_end|>\n'));
    });

    test('extractResponse removes special tokens', () {
      const modelOutput = '''
<|startoftext|><|im_start|>assistant
This is a test response with some content.
It has multiple lines.<|im_end|>
''';

      final cleaned = ChatTemplate.extractResponse(modelOutput);

      expect(cleaned, isNot(contains('<|startoftext|>')));
      expect(cleaned, isNot(contains('<|im_start|>')));
      expect(cleaned, isNot(contains('<|im_end|>')));
      expect(cleaned, contains('This is a test response'));
      expect(cleaned, contains('multiple lines'));
    });

    test('createMessage creates valid Message entity', () {
      final message = ChatTemplate.createMessage(
        conversationId: 'conv-123',
        role: MessageRole.user,
        content: 'Test content',
      );

      expect(message.conversationId, 'conv-123');
      expect(message.role, MessageRole.user);
      expect(message.content, 'Test content');
      expect(message.id, isNotEmpty);
      expect(message.timestamp, isNotNull);
    });

    test('formatMessagesWithTools includes tool definitions', () {
      final messages = [
        Message(
          id: '1',
          conversationId: 'test',
          content: 'Search for cruises',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final tools = [
        {
          'name': 'search_cruises',
          'description': 'Search for available cruises',
          'parameters': {
            'type': 'object',
            'properties': {
              'destination': {'type': 'string'},
            },
          },
        },
      ];

      final prompt = ChatTemplate.formatMessagesWithTools(
        messages: messages,
        tools: tools,
      );

      expect(prompt, contains('List of tools:'));
      expect(prompt, contains('search_cruises'));
      expect(prompt, contains('Search for available cruises'));
    });
  });
}

