import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/huggingface_model_search_service.dart';
import '../../../../core/services/ai_service_provider.dart';
import '../providers/model_search_provider.dart';

/// Page for searching and selecting AI models from HuggingFace
class ModelSearchPage extends ConsumerStatefulWidget {
  const ModelSearchPage({super.key});

  @override
  ConsumerState<ModelSearchPage> createState() => _ModelSearchPageState();
}

class _ModelSearchPageState extends ConsumerState<ModelSearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load initial results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modelSearchProvider.notifier).search();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    ref.read(modelSearchProvider.notifier).search(
      query: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(modelSearchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search AI Models'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ONNX models (max 7B params)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: _buildBody(searchState, theme),
      floatingActionButton: searchState.isLoading
          ? null
          : FloatingActionButton(
              onPressed: _performSearch,
              child: const Icon(Icons.search),
            ),
    );
  }

  Widget _buildBody(ModelSearchState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching HuggingFace models...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Error', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.models.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('No models found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Try a different search query or check your internet connection',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Load All Models'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildModelList(state, theme);
  }

  Widget _buildModelList(ModelSearchState state, ThemeData theme) {
    final modelsByAuthor = state.modelsByAuthor;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: modelsByAuthor.length,
      itemBuilder: (context, index) {
        final entry = modelsByAuthor.entries.elementAt(index);
        return _AuthorSection(
          author: entry.key,
          models: entry.value,
        );
      },
    );
  }
}

/// Section showing models grouped by author
class _AuthorSection extends StatefulWidget {
  final String author;
  final List<HFModelInfo> models;

  const _AuthorSection({
    required this.author,
    required this.models,
  });

  @override
  State<_AuthorSection> createState() => _AuthorSectionState();
}

class _AuthorSectionState extends State<_AuthorSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(
                widget.author[0].toUpperCase(),
                style: theme.textTheme.titleMedium,
              ),
            ),
            title: Text(
              widget.author,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${widget.models.length} models'),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            ...widget.models.map((model) => _ModelTile(model: model)),
        ],
      ),
    );
  }
}

/// Tile showing individual model information
class _ModelTile extends ConsumerWidget {
  final HFModelInfo model;

  const _ModelTile({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sizeB = model.estimatedSizeB;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        model.modelName,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (model.description != null && model.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                model.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (sizeB != null)
                Chip(
                  label: Text('${sizeB.toStringAsFixed(1)}B'),
                  visualDensity: VisualDensity.compact,
                ),
              if (model.downloads != null)
                Chip(
                  label: Text('${_formatNumber(model.downloads!)} ↓'),
                  visualDensity: VisualDensity.compact,
                ),
              if (model.likes != null)
                Chip(
                  label: Text('${_formatNumber(model.likes!)} ♥'),
                  visualDensity: VisualDensity.compact,
                ),
              const Chip(
                label: Text('ONNX'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => _selectModel(context, ref),
      ),
      onTap: () => _selectModel(context, ref),
    );
  }

  Future<void> _selectModel(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to use this model?'),
            const SizedBox(height: 16),
            Text(
              model.id,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (model.estimatedSizeB != null) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ~${model.estimatedSizeB!.toStringAsFixed(1)}B parameters',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Update AI service with new model
      final aiService = ref.read(aiServiceProvider);
      aiService.setModelId(model.id);

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_model_id', model.id);
      await prefs.setString('selected_model_name', model.modelName);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model selected: ${model.modelName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to settings
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

