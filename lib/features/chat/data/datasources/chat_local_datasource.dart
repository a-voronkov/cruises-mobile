import '../../../../core/services/hive_service.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

/// Local data source for chat data using Hive
abstract class ChatLocalDataSource {
  /// Get all conversations
  Future<List<Conversation>> getConversations();

  /// Get a specific conversation
  Future<Conversation?> getConversation(String id);

  /// Create a new conversation
  Future<Conversation> createConversation({
    required String id,
    required String title,
    String? cruiseId,
  });

  /// Update a conversation
  Future<Conversation> updateConversation(Conversation conversation);

  /// Delete a conversation and its messages
  Future<void> deleteConversation(String id);

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId);

  /// Save a message
  Future<Message> saveMessage(Message message);

  /// Delete a message
  Future<void> deleteMessage(String id);

  /// Clear all data
  Future<void> clearAll();
}

/// Implementation of ChatLocalDataSource using Hive
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  @override
  Future<List<Conversation>> getConversations() async {
    final box = HiveService.conversationsBox;
    final models = box.values.whereType<ConversationModel>().toList();

    // Sort by updatedAt descending (newest first)
    models.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    final box = HiveService.conversationsBox;
    final model = box.get(id);
    return model?.toEntity();
  }

  @override
  Future<Conversation> createConversation({
    required String id,
    required String title,
    String? cruiseId,
  }) async {
    final now = DateTime.now();
    final model = ConversationModel(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      cruiseId: cruiseId,
    );

    final box = HiveService.conversationsBox;
    await box.put(id, model);

    return model.toEntity();
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    final box = HiveService.conversationsBox;
    final existing = box.get(conversation.id);

    final model = ConversationModel.fromEntity(
      conversation,
      cruiseId: existing?.cruiseId,
    );

    await box.put(conversation.id, model);
    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    // Delete all messages for this conversation
    final messagesBox = HiveService.messagesBox;
    final keysToDelete = <dynamic>[];

    for (final entry in messagesBox.toMap().entries) {
      if (entry.value.conversationId == id) {
        keysToDelete.add(entry.key);
      }
    }

    await messagesBox.deleteAll(keysToDelete);

    // Delete the conversation
    final conversationsBox = HiveService.conversationsBox;
    await conversationsBox.delete(id);
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final box = HiveService.messagesBox;
    final models = box.values
        .whereType<MessageModel>()
        .where((m) => m.conversationId == conversationId)
        .toList();

    // Sort by timestamp ascending (oldest first)
    models.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Message> saveMessage(Message message) async {
    final model = MessageModel.fromEntity(message);
    final box = HiveService.messagesBox;
    await box.put(message.id, model);

    // Update conversation
    await _updateConversationForMessage(message);

    return message;
  }

  @override
  Future<void> deleteMessage(String id) async {
    final box = HiveService.messagesBox;
    await box.delete(id);
  }

  @override
  Future<void> clearAll() async {
    await HiveService.clearAll();
  }

  /// Update conversation metadata when a message is added
  Future<void> _updateConversationForMessage(Message message) async {
    final box = HiveService.conversationsBox;
    final existing = box.get(message.conversationId);

    if (existing != null) {
      final updated = existing.copyWith(
        updatedAt: DateTime.now(),
        messageCount: existing.messageCount + 1,
        lastMessagePreview: message.content.length > 50
            ? '${message.content.substring(0, 50)}...'
            : message.content,
      );
      await box.put(message.conversationId, updated);
    }
  }
}

