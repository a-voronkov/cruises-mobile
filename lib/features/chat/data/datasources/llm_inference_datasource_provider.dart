import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_service_provider.dart';
import 'llm_inference_datasource.dart';

/// Provider for LLM inference datasource
final llmInferenceDataSourceProvider = Provider<LLMInferenceDataSource>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return LLMInferenceDataSourceImpl(aiService);
});

