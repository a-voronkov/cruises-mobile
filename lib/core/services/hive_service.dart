import 'package:hive_flutter/hive_flutter.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/chat/data/models/conversation_model.dart';

/// Box names for Hive storage
class HiveBoxNames {
  static const String messages = 'messages';
  static const String conversations = 'conversations';
  static const String settings = 'settings';
}

/// Service for managing Hive initialization and adapters
class HiveService {
  static bool _isInitialized = false;

  /// Initialize Hive and register all adapters
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    _registerAdapters();

    // Open boxes
    await _openBoxes();

    _isInitialized = true;
  }

  /// Register all Hive type adapters
  static void _registerAdapters() {
    // Message adapters
    if (!Hive.isAdapterRegistered(HiveTypeIds.messageModel)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.messageRole)) {
      Hive.registerAdapter(MessageRoleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.messageStatus)) {
      Hive.registerAdapter(MessageStatusModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.attachmentModel)) {
      Hive.registerAdapter(AttachmentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.attachmentType)) {
      Hive.registerAdapter(AttachmentTypeModelAdapter());
    }

    // Conversation adapter
    if (!Hive.isAdapterRegistered(HiveTypeIds.conversationModel)) {
      Hive.registerAdapter(ConversationModelAdapter());
    }
  }

  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    await Hive.openBox<MessageModel>(HiveBoxNames.messages);
    await Hive.openBox<ConversationModel>(HiveBoxNames.conversations);
    await Hive.openBox<dynamic>(HiveBoxNames.settings);
  }

  /// Get messages box
  static Box<MessageModel> get messagesBox =>
      Hive.box<MessageModel>(HiveBoxNames.messages);

  /// Get conversations box
  static Box<ConversationModel> get conversationsBox =>
      Hive.box<ConversationModel>(HiveBoxNames.conversations);

  /// Get settings box
  static Box<dynamic> get settingsBox =>
      Hive.box<dynamic>(HiveBoxNames.settings);

  /// Close all boxes
  static Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await messagesBox.clear();
    await conversationsBox.clear();
    await settingsBox.clear();
  }
}

