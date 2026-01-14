import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/model_info.dart';
import '../../../../core/providers/model_download_providers.dart';
import '../../../../core/services/ai_service_provider.dart';
import '../../../../core/providers/model_status_provider.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../settings/presentation/pages/model_search_page.dart';

/// Model setup page - shown on first launch
class ModelSetupPage extends ConsumerStatefulWidget {
  const ModelSetupPage({super.key});

  @override
  ConsumerState<ModelSetupPage> createState() => _ModelSetupPageState();
}

class _ModelSetupPageState extends ConsumerState<ModelSetupPage> {
  bool _isInitializingModel = false;

  @override
  void initState() {
    super.initState();
    // Listen to download state changes
    _checkDownloadCompletion();
  }

  void _checkDownloadCompletion() {
    // Listen to download state
    ref.listenManual(modelDownloadNotifierProvider, (previous, next) {
      // If download just completed, automatically navigate to chat
      if (previous?.isDownloading == true &&
          next.isDownloading == false &&
          next.progress >= 1.0 &&
          !_isInitializingModel) {
        debugPrint('Download completed, auto-navigating to chat');
        _initializeAndGoToChat();
      }
    });
  }

  Future<void> _initializeAndGoToChat() async {
    if (_isInitializingModel) return;

    setState(() {
      _isInitializingModel = true;
    });

    debugPrint('=== ModelSetupPage: Starting initialization ===');

    try {
      // Check if AI service is initialized
      final aiServiceState = ref.read(aiServiceStateProvider);
      debugPrint('AI Service state - isReady: ${aiServiceState.isReady}, error: ${aiServiceState.error}');

      if (!aiServiceState.isReady) {
        debugPrint('❌ AI Service not ready, showing error');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(aiServiceState.error ?? 'AI service not ready'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        await bugsnag.notify(
          Exception('AI Service not ready when trying to navigate to chat'),
          null,
        );
        return;
      }

      // Brief delay for UX
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      debugPrint('✅ Navigating to chat page');

      // Invalidate model status to trigger navigation
      ref.invalidate(modelStatusProvider);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ChatPage()),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _initializeAndGoToChat: $e');
      debugPrint('Stack trace: $stackTrace');

      await bugsnag.notify(e, stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingModel = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadState = ref.watch(modelDownloadNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: _isInitializingModel
          ? _buildInitializingScreen(theme)
          : downloadState.isDownloading
            ? _buildDownloadingScreen(theme, downloadState)
            : _buildWelcomeScreen(theme),
      ),
    );
  }

  Widget _buildInitializingScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Initializing AI model...',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your AI assistant',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingScreen(ThemeData theme, ModelDownloadState downloadState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Downloading model...',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: downloadState.progress),
            const SizedBox(height: 8),
            Text(
              downloadState.status,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(downloadState.progress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Welcome to Cruises AI',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To get started, you need to download an AI model from HuggingFace.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended models:\n'
              '• Llama-3.2-1B-Instruct-ONNX (1.15 GB)\n'
              '• Phi-3-mini-4k-instruct-ONNX (2.3 GB)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ModelSearchPage(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Search for Models'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

}