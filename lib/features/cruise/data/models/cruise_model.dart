import 'package:hive_ce/hive_ce.dart';
import '../../domain/entities/cruise.dart';

part 'cruise_model.g.dart';

/// Hive type IDs for cruise models
/// Starting from 10 to avoid conflicts with chat models (0-5)
class CruiseHiveTypeIds {
  static const int cruiseModel = 10;
  static const int portVisitModel = 11;
}

@HiveType(typeId: CruiseHiveTypeIds.portVisitModel)
class PortVisitModel extends HiveObject {
  @HiveField(0)
  final int day;

  @HiveField(1)
  final String portName;

  @HiveField(2)
  final String? countryName;

  @HiveField(3)
  final String? arrivalTime;

  @HiveField(4)
  final String? departureTime;

  @HiveField(5)
  final bool isEmbarkation;

  @HiveField(6)
  final bool isDisembarkation;

  @HiveField(7)
  final bool isTender;

  PortVisitModel({
    required this.day,
    required this.portName,
    this.countryName,
    this.arrivalTime,
    this.departureTime,
    this.isEmbarkation = false,
    this.isDisembarkation = false,
    this.isTender = false,
  });

  PortVisit toEntity() => PortVisit(
        day: day,
        portName: portName,
        countryName: countryName,
        arrivalTime: arrivalTime,
        departureTime: departureTime,
        isEmbarkation: isEmbarkation,
        isDisembarkation: isDisembarkation,
        isTender: isTender,
      );

  static PortVisitModel fromEntity(PortVisit entity) => PortVisitModel(
        day: entity.day,
        portName: entity.portName,
        countryName: entity.countryName,
        arrivalTime: entity.arrivalTime,
        departureTime: entity.departureTime,
        isEmbarkation: entity.isEmbarkation,
        isDisembarkation: entity.isDisembarkation,
        isTender: entity.isTender,
      );
}

@HiveType(typeId: CruiseHiveTypeIds.cruiseModel)
class CruiseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String cruiseLine;

  @HiveField(3)
  final String shipName;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime endDate;

  @HiveField(6)
  final int durationNights;

  @HiveField(7)
  final String departurePort;

  @HiveField(8)
  final String? returnPort;

  @HiveField(9)
  final List<PortVisitModel> itinerary;

  @HiveField(10)
  final String? region;

  @HiveField(11)
  final String? roomNumber;

  @HiveField(12)
  final String? roomType;

  @HiveField(13)
  final List<String> addons;

  @HiveField(14)
  final int? apiId;

  @HiveField(15)
  final DateTime? lastSyncAt;

  CruiseModel({
    required this.id,
    required this.name,
    required this.cruiseLine,
    required this.shipName,
    required this.startDate,
    required this.endDate,
    required this.durationNights,
    required this.departurePort,
    this.returnPort,
    this.itinerary = const [],
    this.region,
    this.roomNumber,
    this.roomType,
    this.addons = const [],
    this.apiId,
    this.lastSyncAt,
  });

  Cruise toEntity() => Cruise(
        id: id,
        name: name,
        cruiseLine: cruiseLine,
        shipName: shipName,
        startDate: startDate,
        endDate: endDate,
        durationNights: durationNights,
        departurePort: departurePort,
        returnPort: returnPort,
        itinerary: itinerary.map((p) => p.toEntity()).toList(),
        region: region,
        roomNumber: roomNumber,
        roomType: roomType,
        addons: addons,
        apiId: apiId,
        lastSyncAt: lastSyncAt,
      );

  static CruiseModel fromEntity(Cruise entity) => CruiseModel(
        id: entity.id,
        name: entity.name,
        cruiseLine: entity.cruiseLine,
        shipName: entity.shipName,
        startDate: entity.startDate,
        endDate: entity.endDate,
        durationNights: entity.durationNights,
        departurePort: entity.departurePort,
        returnPort: entity.returnPort,
        itinerary: entity.itinerary.map((p) => PortVisitModel.fromEntity(p)).toList(),
        region: entity.region,
        roomNumber: entity.roomNumber,
        roomType: entity.roomType,
        addons: entity.addons,
        apiId: entity.apiId,
        lastSyncAt: entity.lastSyncAt,
      );
}

