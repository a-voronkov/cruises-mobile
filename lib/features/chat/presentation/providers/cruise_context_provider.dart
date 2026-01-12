import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cruise schedule day entry
class CruiseScheduleDay {
  final int day;
  final String port;
  final String portType; // "terminal" or "tender"
  final String? arrivalTime;
  final String? boardingTime;

  const CruiseScheduleDay({
    required this.day,
    required this.port,
    required this.portType,
    this.arrivalTime,
    this.boardingTime,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'port': port,
        'port_type': portType,
        if (arrivalTime != null) 'arrival_time': arrivalTime,
        if (boardingTime != null) 'boarding_time': boardingTime,
      };
}

/// Cruise context data for the AI assistant
class CruiseContext {
  final String? cruiseCompany;
  final String? shipName;
  final String? itinerary;
  final List<CruiseScheduleDay> schedule;
  final String? roomNumber;
  final String? roomType;
  final List<String> addons;
  final String language;

  const CruiseContext({
    this.cruiseCompany,
    this.shipName,
    this.itinerary,
    this.schedule = const [],
    this.roomNumber,
    this.roomType,
    this.addons = const [],
    this.language = 'English',
  });

  bool get hasCruiseData =>
      cruiseCompany != null || shipName != null || schedule.isNotEmpty;

  String toPromptString() {
    if (!hasCruiseData) {
      return 'No cruise data available yet.';
    }

    final buffer = StringBuffer();
    if (cruiseCompany != null) buffer.writeln('Cruise company: $cruiseCompany');
    if (shipName != null) buffer.writeln('Ship name: $shipName');
    if (itinerary != null) buffer.writeln('Itinerary: $itinerary');
    if (schedule.isNotEmpty) {
      buffer.writeln('Schedule:');
      buffer.writeln('[');
      for (final day in schedule) {
        buffer.writeln('  ${day.toJson()},');
      }
      buffer.writeln(']');
    }
    if (roomNumber != null) buffer.writeln('Room number: $roomNumber');
    if (roomType != null) buffer.writeln('Room type: $roomType');
    if (addons.isNotEmpty) buffer.writeln('Addons: ${addons.join(", ")}');

    return buffer.toString();
  }

  CruiseContext copyWith({
    String? cruiseCompany,
    String? shipName,
    String? itinerary,
    List<CruiseScheduleDay>? schedule,
    String? roomNumber,
    String? roomType,
    List<String>? addons,
    String? language,
  }) {
    return CruiseContext(
      cruiseCompany: cruiseCompany ?? this.cruiseCompany,
      shipName: shipName ?? this.shipName,
      itinerary: itinerary ?? this.itinerary,
      schedule: schedule ?? this.schedule,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      addons: addons ?? this.addons,
      language: language ?? this.language,
    );
  }
}

/// Mock cruise data for development
CruiseContext getMockCruiseContext() {
  return CruiseContext(
    cruiseCompany: 'Royal Caribbean',
    shipName: 'Spectrum of the Seas',
    itinerary: '3 Days Shanghai round-trip',
    schedule: [
      const CruiseScheduleDay(
        day: 1,
        port: 'Shanghai',
        portType: 'terminal',
        boardingTime: '18:00',
      ),
      const CruiseScheduleDay(
        day: 2,
        port: 'Jeju',
        portType: 'tender',
        arrivalTime: '10:00',
        boardingTime: '18:00',
      ),
      const CruiseScheduleDay(
        day: 3,
        port: 'Shanghai',
        portType: 'terminal',
        arrivalTime: '08:00',
      ),
    ],
    roomNumber: '12102',
    roomType: 'Balcony',
    addons: ['Classic drinks package'],
    language: 'English',
  );
}

/// Provider for cruise context
/// For now, uses mock data. Will be replaced with real cruise selection.
final cruiseContextProvider = StateProvider<CruiseContext>((ref) {
  return getMockCruiseContext();
});

