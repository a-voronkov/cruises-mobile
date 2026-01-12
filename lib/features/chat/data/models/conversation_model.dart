import 'package:hive_ce/hive_ce.dart';
import '../../domain/entities/conversation.dart';
import 'message_model.dart';

part 'conversation_model.g.dart';

@HiveType(typeId: HiveTypeIds.conversationModel)
class ConversationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime updatedAt;

  @HiveField(4)
  final int messageCount;

  @HiveField(5)
  final String? lastMessagePreview;

  /// Cruise ID this conversation belongs to (for future use)
  @HiveField(6)
  final String? cruiseId;

  ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessagePreview,
    this.cruiseId,
  });

  Conversation toEntity() => Conversation(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messageCount: messageCount,
        lastMessagePreview: lastMessagePreview,
      );

  static ConversationModel fromEntity(
    Conversation entity, {
    String? cruiseId,
  }) =>
      ConversationModel(
        id: entity.id,
        title: entity.title,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        messageCount: entity.messageCount,
        lastMessagePreview: entity.lastMessagePreview,
        cruiseId: cruiseId,
      );

  ConversationModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessagePreview,
    String? cruiseId,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      cruiseId: cruiseId ?? this.cruiseId,
    );
  }
}

