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

/// Notifier for cruise search parameters (replaces StateProvider in Riverpod 3.x)
class CruiseSearchParamsNotifier extends Notifier<CruiseSearchParams> {
  @override
  CruiseSearchParams build() => const CruiseSearchParams();

  void update({int? departurePortId, DateTime? startDate, DateTime? endDate}) {
    state = CruiseSearchParams(
      departurePortId: departurePortId ?? state.departurePortId,
      startDate: startDate ?? state.startDate,
      endDate: endDate ?? state.endDate,
    );
  }

  void reset() {
    state = const CruiseSearchParams();
  }
}

/// Provider for cruise search parameters
final cruiseSearchParamsProvider =
    NotifierProvider<CruiseSearchParamsNotifier, CruiseSearchParams>(
        CruiseSearchParamsNotifier.new);

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

/// Notifier for the currently selected/active cruise
class ActiveCruiseNotifier extends Notifier<Cruise?> {
  @override
  Cruise? build() {
    // Try to get from saved cruises
    final saved = ref.watch(savedCruisesProvider);
    if (saved.isNotEmpty) {
      // Return the most recent cruise by start date
      final sorted = [...saved]
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      return sorted.first;
    }
    return null;
  }

  void setActiveCruise(Cruise cruise) {
    state = cruise;
  }

  void clear() {
    state = null;
  }
}

/// Provider for the currently selected/active cruise
final activeCruiseProvider =
    NotifierProvider<ActiveCruiseNotifier, Cruise?>(ActiveCruiseNotifier.new);

/// Notifier for managing cruise operations
class CruiseNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Save a cruise to local storage
  Future<void> saveCruise(Cruise cruise) async {
    state = const AsyncValue.loading();
    try {
      final box = HiveService.cruisesBox;
      final model = CruiseModel.fromEntity(cruise);
      await box.put(cruise.id, model);
      ref.invalidateSelf();
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
      ref.invalidateSelf();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Set the active cruise
  void setActiveCruise(Cruise cruise) {
    ref.read(activeCruiseProvider.notifier).setActiveCruise(cruise);
  }
}

/// Provider for cruise operations
final cruiseNotifierProvider =
    NotifierProvider<CruiseNotifier, AsyncValue<void>>(CruiseNotifier.new);

