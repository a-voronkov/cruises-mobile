import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/hive_service.dart';
import 'core/services/ai_service_provider.dart';
import 'core/config/api_config.dart';
import 'core/providers/model_status_provider.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/model_management/presentation/pages/model_setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bugsnag for error tracking
  await bugsnag.start(apiKey: 'ff5741e8bfedbe083742cad85830d768');

  // Initialize Hive with adapters and open boxes
  await HiveService.initialize();

  // Initialize dependency injection
  await configureDependencies();

  runApp(
    ProviderScope(
      overrides: [
        // Initialize AI service with API key
        aiServiceInitializerProvider,
      ],
      child: const CruisesApp(),
    ),
  );
}

class CruisesApp extends ConsumerWidget {
  const CruisesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Cruises Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppInitializer(),
    );
  }
}

/// Determines which page to show on app start
class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if model is downloaded and ready
    final modelStatus = ref.watch(modelStatusProvider);

    return modelStatus.when(
      data: (isReady) {
        if (isReady) {
          return const ChatPage();
        } else {
          return const ModelSetupPage();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(modelStatusProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder providers - will be implemented in respective features
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

