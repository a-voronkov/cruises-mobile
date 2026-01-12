import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_local_datasource.dart';

/// Provider for ChatLocalDataSource
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  return ChatLocalDataSourceImpl();
});

