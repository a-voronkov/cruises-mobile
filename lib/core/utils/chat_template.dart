import '../constants/app_constants.dart';
import '../../features/chat/domain/entities/message.dart';
import '../../features/chat/presentation/providers/cruise_context_provider.dart';

/// Chat template formatter for LFM2.5 model
/// 
/// LFM2.5 uses a ChatML-like format:
/// ```
/// <|startoftext|><|im_start|>system
/// You are a helpful assistant trained by Liquid AI.<|im_end|>
/// <|im_start|>user
/// What is C. elegans?<|im_end|>
/// <|im_start|>assistant
/// ```
class ChatTemplate {
  ChatTemplate._();

  /// Format a list of messages into LFM2.5 chat template format
  /// 
  /// [messages] - List of conversation messages
  /// [includeSystemPrompt] - Whether to include system prompt (default: true)
  /// [addGenerationPrompt] - Whether to add assistant prompt at the end (default: true)
  static String formatMessages({
    required List<Message> messages,
    bool includeSystemPrompt = true,
    bool addGenerationPrompt = true,
  }) {
    final buffer = StringBuffer();

    // Start with BOS token
    buffer.write(AppConstants.bosToken);

    // Add system prompt if requested
    if (includeSystemPrompt) {
      buffer.write(AppConstants.imStartToken);
      buffer.write('system\n');
      buffer.write(AppConstants.systemPrompt);
      buffer.write(AppConstants.imEndToken);
      buffer.write('\n');
    }

    // Add conversation messages
    for (final message in messages) {
      buffer.write(AppConstants.imStartToken);
      buffer.write(_roleToString(message.role));
      buffer.write('\n');
      buffer.write(message.content);
      buffer.write(AppConstants.imEndToken);
      buffer.write('\n');
    }

    // Add generation prompt for assistant response
    if (addGenerationPrompt) {
      buffer.write(AppConstants.imStartToken);
      buffer.write('assistant\n');
    }

    return buffer.toString();
  }

  /// Format a single user message (for simple queries)
  static String formatUserMessage(String content) {
    final buffer = StringBuffer();

    buffer.write(AppConstants.bosToken);
    buffer.write(AppConstants.imStartToken);
    buffer.write('system\n');
    buffer.write(AppConstants.systemPrompt);
    buffer.write(AppConstants.imEndToken);
    buffer.write('\n');
    buffer.write(AppConstants.imStartToken);
    buffer.write('user\n');
    buffer.write(content);
    buffer.write(AppConstants.imEndToken);
    buffer.write('\n');
    buffer.write(AppConstants.imStartToken);
    buffer.write('assistant\n');

    return buffer.toString();
  }

  /// Format messages with cruise context for the system prompt
  static String formatMessagesWithContext({
    required List<Message> messages,
    required CruiseContext cruiseContext,
    bool addGenerationPrompt = true,
  }) {
    final buffer = StringBuffer();

    // Start with BOS token
    buffer.write(AppConstants.bosToken);

    // Add system prompt with cruise context
    buffer.write(AppConstants.imStartToken);
    buffer.write('system\n');
    buffer.write(_buildCruiseSystemPrompt(cruiseContext));
    buffer.write(AppConstants.imEndToken);
    buffer.write('\n');

    // Add conversation messages (skip system messages and welcome)
    for (final message in messages) {
      if (message.role == MessageRole.system) continue;

      buffer.write(AppConstants.imStartToken);
      buffer.write(_roleToString(message.role));
      buffer.write('\n');
      buffer.write(message.content);
      buffer.write(AppConstants.imEndToken);
      buffer.write('\n');
    }

    // Add generation prompt for assistant response
    if (addGenerationPrompt) {
      buffer.write(AppConstants.imStartToken);
      buffer.write('assistant\n');
    }

    return buffer.toString();
  }

  /// Build system prompt with cruise context
  static String _buildCruiseSystemPrompt(CruiseContext context) {
    final buffer = StringBuffer();

    buffer.writeln('You are an offline cruise consultant assistant.');
    buffer.writeln('You help passengers with their cruise experience, shore excursions, and travel planning.');
    buffer.writeln('Be helpful, concise, and friendly.');
    buffer.writeln('');
    buffer.writeln('The user is going on a cruise. Here is their cruise information:');
    buffer.writeln(context.toPromptString());
    buffer.writeln('');
    buffer.writeln('Language preference: ${context.language}');

    return buffer.toString();
  }

  /// Extract assistant response from model output
  /// Removes special tokens and formatting
  static String extractResponse(String modelOutput) {
    String response = modelOutput;

    // Remove BOS token if present
    response = response.replaceAll(AppConstants.bosToken, '');

    // Remove im_start/im_end tokens
    response = response.replaceAll(AppConstants.imStartToken, '');
    response = response.replaceAll(AppConstants.imEndToken, '');

    // Remove role labels
    response = response.replaceAll(RegExp(r'^(system|user|assistant)\n'), '');

    // Trim whitespace
    response = response.trim();

    return response;
  }

  /// Convert MessageRole to string for template
  static String _roleToString(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }

  /// Create a Message from role and content
  static Message createMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );
  }

  /// Format messages for tool use (function calling)
  /// 
  /// Example with tools:
  /// ```
  /// <|startoftext|><|im_start|>system
  /// List of tools: [{"name": "get_weather", ...}]<|im_end|>
  /// <|im_start|>user
  /// What's the weather?<|im_end|>
  /// <|im_start|>assistant
  /// <|tool_call_start|>[get_weather(location="New York")]<|tool_call_end|>
  /// ```
  static String formatMessagesWithTools({
    required List<Message> messages,
    required List<Map<String, dynamic>> tools,
  }) {
    final buffer = StringBuffer();

    buffer.write(AppConstants.bosToken);
    buffer.write(AppConstants.imStartToken);
    buffer.write('system\n');
    buffer.write(AppConstants.systemPrompt);
    buffer.write('\n');
    buffer.write('List of tools: $tools');
    buffer.write(AppConstants.imEndToken);
    buffer.write('\n');

    for (final message in messages) {
      buffer.write(AppConstants.imStartToken);
      buffer.write(_roleToString(message.role));
      buffer.write('\n');
      buffer.write(message.content);
      buffer.write(AppConstants.imEndToken);
      buffer.write('\n');
    }

    buffer.write(AppConstants.imStartToken);
    buffer.write('assistant\n');

    return buffer.toString();
  }

  /// Format cruise context into a string for system prompt
  static String formatCruiseContext(CruiseContext context) {
    if (!context.hasCruiseData) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.write('Current cruise information: ');

    if (context.cruiseCompany != null) {
      buffer.write('${context.cruiseCompany} ');
    }

    if (context.shipName != null) {
      buffer.write('on ${context.shipName}');
    }

    if (context.itinerary != null) {
      buffer.write(', ${context.itinerary}');
    }

    if (context.roomType != null) {
      buffer.write(', ${context.roomType} cabin');
    }

    if (context.addons.isNotEmpty) {
      buffer.write(', with ${context.addons.join(", ")}');
    }

    buffer.write('. ');

    return buffer.toString();
  }
}

