import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

// Service Locator instance
final getIt = GetIt.instance;

/// Configure all dependencies for the application
Future<void> configureDependencies() async {
  // External dependencies
  await _registerExternalDependencies();

  // Core services
  _registerCoreServices();

  // Feature dependencies
  _registerChatFeature();
  _registerModelManagementFeature();
}

/// Register external dependencies (Dio, Hive, etc.)
Future<void> _registerExternalDependencies() async {
  // Dio for HTTP requests
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors for logging
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  getIt.registerSingleton<Dio>(dio);

  // Get application documents directory
  final appDir = await getApplicationDocumentsDirectory();
  getIt.registerSingleton<String>(
    appDir.path,
    instanceName: 'appDocumentsPath',
  );
}

/// Register core services
void _registerCoreServices() {
  // Logger, validators, etc. can be registered here
  // For now, we'll keep it simple
}

/// Register Chat feature dependencies
void _registerChatFeature() {
  // Data sources
  // getIt.registerLazySingleton<ChatLocalDataSource>(
  //   () => ChatLocalDataSourceImpl(getIt()),
  // );

  // Repositories
  // getIt.registerLazySingleton<ChatRepository>(
  //   () => ChatRepositoryImpl(
  //     localDataSource: getIt(),
  //     llmDataSource: getIt(),
  //   ),
  // );

  // Use cases
  // getIt.registerLazySingleton(() => SendMessage(getIt()));
  // getIt.registerLazySingleton(() => GetConversations(getIt()));
  // getIt.registerLazySingleton(() => DeleteConversation(getIt()));
}

/// Register Model Management feature dependencies
void _registerModelManagementFeature() {
  // Data sources
  // getIt.registerLazySingleton<ModelDownloadDataSource>(
  //   () => ModelDownloadDataSourceImpl(getIt()),
  // );

  // getIt.registerLazySingleton<ModelStorageDataSource>(
  //   () => ModelStorageDataSourceImpl(getIt()),
  // );

  // Repositories
  // getIt.registerLazySingleton<ModelRepository>(
  //   () => ModelRepositoryImpl(
  //     downloadDataSource: getIt(),
  //     storageDataSource: getIt(),
  //   ),
  // );

  // Use cases
  // getIt.registerLazySingleton(() => DownloadModel(getIt()));
  // getIt.registerLazySingleton(() => LoadModel(getIt()));
  // getIt.registerLazySingleton(() => CheckModelStatus(getIt()));
}

