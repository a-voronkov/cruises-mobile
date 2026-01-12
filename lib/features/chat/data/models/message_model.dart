import 'package:hive_ce/hive_ce.dart';
import '../../domain/entities/message.dart';

part 'message_model.g.dart';

/// Hive type IDs for chat models
class HiveTypeIds {
  static const int messageModel = 0;
  static const int messageRole = 1;
  static const int messageStatus = 2;
  static const int attachmentModel = 3;
  static const int attachmentType = 4;
  static const int conversationModel = 5;
}

@HiveType(typeId: HiveTypeIds.messageRole)
enum MessageRoleModel {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system,
}

@HiveType(typeId: HiveTypeIds.messageStatus)
enum MessageStatusModel {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  error,
}

@HiveType(typeId: HiveTypeIds.attachmentType)
enum AttachmentTypeModel {
  @HiveField(0)
  image,
  @HiveField(1)
  file,
  @HiveField(2)
  voice,
}

@HiveType(typeId: HiveTypeIds.attachmentModel)
class AttachmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final AttachmentTypeModel type;

  @HiveField(3)
  final String? mimeType;

  @HiveField(4)
  final int? sizeBytes;

  AttachmentModel({
    required this.id,
    required this.path,
    required this.type,
    this.mimeType,
    this.sizeBytes,
  });

  MessageAttachment toEntity() => MessageAttachment(
        id: id,
        path: path,
        type: _mapAttachmentType(type),
        mimeType: mimeType,
        sizeBytes: sizeBytes,
      );

  static AttachmentModel fromEntity(MessageAttachment entity) => AttachmentModel(
        id: entity.id,
        path: entity.path,
        type: _mapAttachmentTypeToModel(entity.type),
        mimeType: entity.mimeType,
        sizeBytes: entity.sizeBytes,
      );

  static AttachmentType _mapAttachmentType(AttachmentTypeModel type) {
    switch (type) {
      case AttachmentTypeModel.image:
        return AttachmentType.image;
      case AttachmentTypeModel.file:
        return AttachmentType.file;
      case AttachmentTypeModel.voice:
        return AttachmentType.voice;
    }
  }

  static AttachmentTypeModel _mapAttachmentTypeToModel(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return AttachmentTypeModel.image;
      case AttachmentType.file:
        return AttachmentTypeModel.file;
      case AttachmentType.voice:
        return AttachmentTypeModel.voice;
    }
  }
}

@HiveType(typeId: HiveTypeIds.messageModel)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final MessageRoleModel role;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final List<AttachmentModel>? attachments;

  @HiveField(6)
  final MessageStatusModel status;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.attachments,
    this.status = MessageStatusModel.sent,
  });

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        content: content,
        role: _mapRole(role),
        timestamp: timestamp,
        attachments: attachments?.map((a) => a.toEntity()).toList(),
        status: _mapStatus(status),
      );

  static MessageModel fromEntity(Message entity) => MessageModel(
        id: entity.id,
        conversationId: entity.conversationId,
        content: entity.content,
        role: _mapRoleToModel(entity.role),
        timestamp: entity.timestamp,
        attachments: entity.attachments
            ?.map((a) => AttachmentModel.fromEntity(a))
            .toList(),
        status: _mapStatusToModel(entity.status),
      );

  static MessageRole _mapRole(MessageRoleModel role) {
    switch (role) {
      case MessageRoleModel.user:
        return MessageRole.user;
      case MessageRoleModel.assistant:
        return MessageRole.assistant;
      case MessageRoleModel.system:
        return MessageRole.system;
    }
  }

  static MessageRoleModel _mapRoleToModel(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return MessageRoleModel.user;
      case MessageRole.assistant:
        return MessageRoleModel.assistant;
      case MessageRole.system:
        return MessageRoleModel.system;
    }
  }

  static MessageStatus _mapStatus(MessageStatusModel status) {
    switch (status) {
      case MessageStatusModel.sending:
        return MessageStatus.sending;
      case MessageStatusModel.sent:
        return MessageStatus.sent;
      case MessageStatusModel.error:
        return MessageStatus.error;
    }
  }

  static MessageStatusModel _mapStatusToModel(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return MessageStatusModel.sending;
      case MessageStatus.sent:
        return MessageStatusModel.sent;
      case MessageStatus.error:
        return MessageStatusModel.error;
    }
  }
}

