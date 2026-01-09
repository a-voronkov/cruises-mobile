import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/llama_service_provider.dart';

/// Page for initializing the LLM model
/// 
/// Shows progress and handles errors during model initialization
class ModelInitializationPage extends ConsumerStatefulWidget {
  const ModelInitializationPage({super.key});

  @override
  ConsumerState<ModelInitializationPage> createState() =>
      _ModelInitializationPageState();
}

class _ModelInitializationPageState
    extends ConsumerState<ModelInitializationPage> {
  @override
  void initState() {
    super.initState();
    // Start initialization when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modelInitializationProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelInitializationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Icon(
                Icons.smart_toy_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Cruises AI Assistant',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Status message
              Text(
                _getStatusMessage(state),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Progress indicator or error
              if (state.isLoading) ...[
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ] else if (state.error != null) ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(modelInitializationProvider.notifier).initialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ] else if (state.isInitialized) ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ready to chat!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/chat');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chatting'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Model info
              if (state.isInitialized || state.isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Model', 'LFM2.5-1.2B-Instruct'),
                      _buildInfoRow('Size', '~700 MB'),
                      _buildInfoRow('Context', '32K tokens'),
                      _buildInfoRow('Languages', '8 languages'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(ModelInitializationState state) {
    if (state.isLoading) {
      if (state.progress < 0.3) {
        return 'Locating model file...';
      } else if (state.progress < 0.7) {
        return 'Loading model into memory...';
      } else {
        return 'Initializing inference engine...';
      }
    } else if (state.error != null) {
      return 'Failed to initialize model';
    } else if (state.isInitialized) {
      return 'Model loaded successfully!';
    } else {
      return 'Preparing AI assistant...';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

