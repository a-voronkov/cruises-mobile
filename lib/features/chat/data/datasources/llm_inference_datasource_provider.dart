import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/llama_service_provider.dart';
import 'llm_inference_datasource.dart';

/// Provider for LLM inference datasource
final llmInferenceDataSourceProvider = Provider<LLMInferenceDataSource>((ref) {
  final llamaService = ref.watch(llamaServiceProvider);
  return LLMInferenceDataSourceImpl(llamaService);
});

