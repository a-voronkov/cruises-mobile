import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_service_provider.dart';

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
    // Cloud-based AI service is always ready, no initialization needed
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiServiceStateProvider);

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
              if (state.error != null) ...[
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
                    ref.read(aiServiceStateProvider.notifier).clearError();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ] else if (state.isReady) ...[
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

              // Service info
              if (state.isReady)
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
                        'Service Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Provider', 'HuggingFace Inference API'),
                      _buildInfoRow('Model', 'Qwen/Qwen2.5-72B-Instruct'),
                      _buildInfoRow('Type', 'Cloud-based'),
                      _buildInfoRow('Status', 'Always available'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(AIServiceState state) {
    if (state.error != null) {
      return 'Failed to connect to AI service';
    } else if (state.isReady) {
      return 'AI service ready!';
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

