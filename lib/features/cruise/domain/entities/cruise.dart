import 'package:freezed_annotation/freezed_annotation.dart';

part 'cruise.freezed.dart';
part 'cruise.g.dart';

/// Port visit during a cruise
@freezed
class PortVisit with _$PortVisit {
  const factory PortVisit({
    required int day,
    required String portName,
    String? countryName,
    String? arrivalTime,
    String? departureTime,
    @Default(false) bool isEmbarkation,
    @Default(false) bool isDisembarkation,
    @Default(false) bool isTender,
  }) = _PortVisit;

  factory PortVisit.fromJson(Map<String, dynamic> json) =>
      _$PortVisitFromJson(json);
}

/// Cruise data entity
@freezed
class Cruise with _$Cruise {
  const Cruise._();

  const factory Cruise({
    /// Unique identifier (from API or generated)
    required String id,

    /// Cruise name/title
    required String name,

    /// Cruise line company
    required String cruiseLine,

    /// Ship name
    required String shipName,

    /// Start date
    required DateTime startDate,

    /// End date
    required DateTime endDate,

    /// Duration in nights
    required int durationNights,

    /// Departure port name
    required String departurePort,

    /// Return port name (if different)
    String? returnPort,

    /// Itinerary - list of port visits
    @Default([]) List<PortVisit> itinerary,

    /// Region (e.g., "Caribbean", "Mediterranean")
    String? region,

    /// Room number (user's booking)
    String? roomNumber,

    /// Room type (e.g., "Balcony", "Suite")
    String? roomType,

    /// Purchased add-ons
    @Default([]) List<String> addons,

    /// API source ID (for syncing)
    int? apiId,

    /// Last sync timestamp
    DateTime? lastSyncAt,
  }) = _Cruise;

  factory Cruise.fromJson(Map<String, dynamic> json) => _$CruiseFromJson(json);

  /// Human-readable itinerary summary
  String get itinerarySummary {
    if (itinerary.isEmpty) {
      return '$departurePort round-trip';
    }
    final ports = itinerary.map((p) => p.portName).toSet().toList();
    if (ports.length <= 3) {
      return ports.join(' → ');
    }
    return '${ports.first} → ... → ${ports.last}';
  }

  /// Duration in days
  int get durationDays => durationNights + 1;
}

