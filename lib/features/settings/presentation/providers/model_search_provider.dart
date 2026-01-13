import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/huggingface_model_search_service.dart';
import '../../../../core/config/api_config.dart';

/// Provider for HuggingFace model search service
final modelSearchServiceProvider = Provider<HuggingFaceModelSearchService>((ref) {
  return HuggingFaceModelSearchService(
    apiKey: ApiConfig.isConfigured ? ApiConfig.huggingFaceApiKey : null,
  );
});

/// State for model search
class ModelSearchState {
  final List<HFModelInfo> models;
  final bool isLoading;
  final String? error;
  final String query;
  final double maxSizeB;

  const ModelSearchState({
    this.models = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.maxSizeB = 7.0,
  });

  ModelSearchState copyWith({
    List<HFModelInfo>? models,
    bool? isLoading,
    String? error,
    String? query,
    double? maxSizeB,
  }) {
    return ModelSearchState(
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      maxSizeB: maxSizeB ?? this.maxSizeB,
    );
  }

  /// Group models by author
  Map<String, List<HFModelInfo>> get modelsByAuthor {
    final grouped = <String, List<HFModelInfo>>{};
    for (final model in models) {
      grouped.putIfAbsent(model.author, () => []).add(model);
    }
    // Sort authors by number of models (descending)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map.fromEntries(sortedEntries);
  }
}

/// Notifier for model search
class ModelSearchNotifier extends StateNotifier<ModelSearchState> {
  final HuggingFaceModelSearchService _searchService;

  ModelSearchNotifier(this._searchService) : super(const ModelSearchState());

  /// Search for models
  Future<void> search({String? query, double? maxSizeB}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      query: query,
      maxSizeB: maxSizeB,
    );

    try {
      final models = await _searchService.searchONNXModels(
        query: query,
        maxSizeB: maxSizeB ?? state.maxSizeB,
        limit: 100,
        sort: 'downloads',
      );

      state = state.copyWith(
        models: models,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear search results
  void clear() {
    state = const ModelSearchState();
  }
}

/// Provider for model search state
final modelSearchProvider = StateNotifierProvider<ModelSearchNotifier, ModelSearchState>((ref) {
  final searchService = ref.watch(modelSearchServiceProvider);
  return ModelSearchNotifier(searchService);
});

