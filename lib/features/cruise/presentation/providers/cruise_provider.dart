import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/hive_service.dart';
import '../../data/models/cruise_model.dart';
import '../../data/services/cruise_api_service.dart';
import '../../domain/entities/cruise.dart';

/// Provider for CruiseApiService singleton
final cruiseApiServiceProvider = Provider<CruiseApiService>((ref) {
  return CruiseApiService();
});

/// Provider for departure ports from API
final departurePortsProvider = FutureProvider<List<PortDto>>((ref) async {
  final service = ref.read(cruiseApiServiceProvider);
  return service.getDeparturePorts();
});

/// Search parameters for cruises
class CruiseSearchParams {
  final int? departurePortId;
  final DateTime? startDate;
  final DateTime? endDate;

  const CruiseSearchParams({
    this.departurePortId,
    this.startDate,
    this.endDate,
  });
}

/// Provider for cruise search parameters
final cruiseSearchParamsProvider = StateProvider<CruiseSearchParams>((ref) {
  return const CruiseSearchParams();
});

/// Provider for cruise search results
final cruiseSearchResultsProvider =
    FutureProvider<List<CruiseSearchResultDto>>((ref) async {
  final service = ref.read(cruiseApiServiceProvider);
  final params = ref.watch(cruiseSearchParamsProvider);

  return service.searchCruises(
    departurePortId: params.departurePortId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Provider for saved cruises from local storage
final savedCruisesProvider = Provider<List<Cruise>>((ref) {
  final box = HiveService.cruisesBox;
  return box.values.map((m) => m.toEntity()).toList();
});

/// Provider for the currently selected/active cruise
final activeCruiseProvider = StateProvider<Cruise?>((ref) {
  // Try to get from saved cruises
  final saved = ref.watch(savedCruisesProvider);
  if (saved.isNotEmpty) {
    // Return the most recent cruise by start date
    final sorted = [...saved]..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted.first;
  }
  return null;
});

/// Notifier for managing cruise operations
class CruiseNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CruiseNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Save a cruise to local storage
  Future<void> saveCruise(Cruise cruise) async {
    state = const AsyncValue.loading();
    try {
      final box = HiveService.cruisesBox;
      final model = CruiseModel.fromEntity(cruise);
      await box.put(cruise.id, model);
      _ref.invalidateSelf();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a cruise from local storage
  Future<void> deleteCruise(String cruiseId) async {
    state = const AsyncValue.loading();
    try {
      final box = HiveService.cruisesBox;
      await box.delete(cruiseId);
      _ref.invalidateSelf();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Set the active cruise
  void setActiveCruise(Cruise cruise) {
    _ref.read(activeCruiseProvider.notifier).state = cruise;
  }
}

/// Provider for cruise operations
final cruiseNotifierProvider =
    StateNotifierProvider<CruiseNotifier, AsyncValue<void>>((ref) {
  return CruiseNotifier(ref);
});

