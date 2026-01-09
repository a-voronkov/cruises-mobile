import 'package:equatable/equatable.dart';

/// Represents a single message in a conversation
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final List<MessageAttachment>? attachments;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.attachments,
    this.status = MessageStatus.sent,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    List<MessageAttachment>? attachments,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        content,
        role,
        timestamp,
        attachments,
        status,
      ];
}

/// Message role (user or assistant)
enum MessageRole {
  user,
  assistant,
  system,
}

/// Message status
enum MessageStatus {
  sending,
  sent,
  error,
}

/// Message attachment (image, file, etc.)
class MessageAttachment extends Equatable {
  final String id;
  final String path;
  final AttachmentType type;
  final String? mimeType;
  final int? sizeBytes;

  const MessageAttachment({
    required this.id,
    required this.path,
    required this.type,
    this.mimeType,
    this.sizeBytes,
  });

  @override
  List<Object?> get props => [id, path, type, mimeType, sizeBytes];
}

/// Attachment type
enum AttachmentType {
  image,
  file,
  voice,
}

