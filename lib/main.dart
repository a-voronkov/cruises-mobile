import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/model_management/presentation/pages/model_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: CruisesApp(),
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

final modelStatusProvider = FutureProvider<bool>((ref) async {
  // TODO: Implement actual model status check
  // For now, return false to show setup page
  await Future<void>.delayed(const Duration(seconds: 1));
  return false;
});

