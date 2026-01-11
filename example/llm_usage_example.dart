// ignore_for_file: avoid_print

// Example of using LlamaService for LLM inference
// This is a standalone example showing how to use the LLM integration

import 'package:cruises_mobile/core/services/llama_service.dart';
import 'package:cruises_mobile/core/utils/chat_template.dart';
import 'package:cruises_mobile/features/chat/domain/entities/message.dart';

void main() async {
  print('=== LFM2.5 LLM Usage Example ===\n');

  // Create LlamaService instance
  final llamaService = LlamaService();

  try {
    // Step 1: Initialize the model
    print('Step 1: Initializing model...');
    final initialized = await llamaService.initialize(
      onProgress: (progress) {
        print('  Progress: ${(progress * 100).toInt()}%');
      },
    );

    if (!initialized) {
      print('❌ Failed to initialize model');
      print('Make sure the model file exists in models/ directory');
      return;
    }

    print('✅ Model initialized successfully!\n');

    // Step 2: Simple single-message inference
    print('Step 2: Simple inference (single message)');
    print('User: What is a cruise vacation?');
    print('Assistant: ');

    final simplePrompt = ChatTemplate.formatUserMessage(
      'What is a cruise vacation? Give a brief answer.',
    );

    await for (final token in llamaService.generateStream(simplePrompt)) {
      // Print tokens as they arrive (streaming)
      print(token);
    }

    print('\n');

    // Step 3: Conversation with history
    print('Step 3: Conversation with history');

    final conversationMessages = [
      Message(
        id: '1',
        conversationId: 'example',
        content: 'I want to plan a Mediterranean cruise',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
      Message(
        id: '2',
        conversationId: 'example',
        content:
            'Great choice! The Mediterranean offers beautiful destinations. '
            'How many days would you like your cruise to be?',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
      Message(
        id: '3',
        conversationId: 'example',
        content: '7 days would be perfect',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    ];

    print('Conversation history:');
    for (final msg in conversationMessages) {
      print('  ${msg.role.name}: ${msg.content}');
    }

    print('\nGenerating response...');
    print('Assistant: ');

    final conversationPrompt = ChatTemplate.formatMessages(
      messages: conversationMessages,
      includeSystemPrompt: true,
      addGenerationPrompt: true,
    );

    final response = StringBuffer();
    await for (final token in llamaService.generateStream(conversationPrompt)) {
      response.write(token);
      print(token);
    }

    print('\n');

    // Step 4: Extract clean response
    print('Step 4: Clean response extraction');
    final cleanResponse = ChatTemplate.extractResponse(response.toString());
    print('Cleaned response: $cleanResponse\n');

    // Step 5: Non-streaming inference
    print('Step 5: Non-streaming inference');
    print('User: What are the top 3 Mediterranean ports?');
    print('Generating...');

    final quickPrompt = ChatTemplate.formatUserMessage(
      'List the top 3 Mediterranean cruise ports. Be brief.',
    );

    final fullResponse = await llamaService.generate(
      quickPrompt,
      onToken: (token) {
        // Optional: do something with each token
      },
    );

    print('Assistant: $fullResponse\n');

    // Step 6: Using with tools (function calling)
    print('Step 6: Function calling example');

    final tools = [
      {
        'name': 'search_cruises',
        'description': 'Search for available cruises',
        'parameters': {
          'type': 'object',
          'properties': {
            'destination': {
              'type': 'string',
              'description': 'Cruise destination',
            },
            'duration_days': {
              'type': 'integer',
              'description': 'Number of days',
            },
          },
          'required': ['destination', 'duration_days'],
        },
      },
    ];

    final toolMessages = [
      Message(
        id: '1',
        conversationId: 'tool-example',
        content: 'Find me a 7-day Caribbean cruise',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    ];

    final toolPrompt = ChatTemplate.formatMessagesWithTools(
      messages: toolMessages,
      tools: tools,
    );

    print('User: Find me a 7-day Caribbean cruise');
    print('Assistant (with tools): ');

    await for (final token in llamaService.generateStream(toolPrompt)) {
      print(token);
    }

    print('\n');

    print('✅ Example completed successfully!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Step 7: Cleanup
    print('\nCleaning up...');
    await llamaService.dispose();
    print('✅ Resources released');
  }
}

