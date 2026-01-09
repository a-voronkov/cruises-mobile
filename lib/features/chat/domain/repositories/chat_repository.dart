import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Send a message and get AI response
  /// Returns a stream of response chunks for streaming
  Stream<Either<Failure, String>> sendMessage({
    required String conversationId,
    required String content,
    List<MessageAttachment>? attachments,
  });

  /// Get all conversations
  Future<Either<Failure, List<Conversation>>> getConversations();

  /// Get a specific conversation
  Future<Either<Failure, Conversation>> getConversation(String id);

  /// Get messages for a conversation
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);

  /// Create a new conversation
  Future<Either<Failure, Conversation>> createConversation(String title);

  /// Delete a conversation
  Future<Either<Failure, void>> deleteConversation(String id);

  /// Update conversation title
  Future<Either<Failure, Conversation>> updateConversationTitle({
    required String id,
    required String title,
  });

  /// Save a message locally
  Future<Either<Failure, Message>> saveMessage(Message message);

  /// Delete a message
  Future<Either<Failure, void>> deleteMessage(String id);

  /// Clear all conversations
  Future<Either<Failure, void>> clearAllConversations();
}

