import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/cruise.dart';

/// DTO for port from API
class PortDto {
  final int id;
  final String name;
  final String? countryName;

  PortDto({required this.id, required this.name, this.countryName});

  factory PortDto.fromJson(Map<String, dynamic> json) => PortDto(
        id: json['id'] as int,
        name: json['name'] as String,
        countryName: json['country']?['name'] as String?,
      );
}

/// DTO for cruise search result from API
/// Based on cruises.voronkov.club/api/cruises/search response format
class CruiseSearchResultDto {
  final int id;
  final String? cruiseName;
  final String shipName;
  final String cruiseLine;
  final DateTime startDate;
  final DateTime endDate;
  final int durationNights;
  final String departurePort;
  final String? returnPort;
  final String? region;
  final double? priceFrom;
  final String? currency;

  CruiseSearchResultDto({
    required this.id,
    this.cruiseName,
    required this.shipName,
    required this.cruiseLine,
    required this.startDate,
    required this.endDate,
    required this.durationNights,
    required this.departurePort,
    this.returnPort,
    this.region,
    this.priceFrom,
    this.currency,
  });

  /// Parse from API response format (snake_case fields)
  factory CruiseSearchResultDto.fromJson(Map<String, dynamic> json) {
    return CruiseSearchResultDto(
      id: json['id'] as int,
      cruiseName: json['cruise_id'] as String? ?? json['description'] as String?,
      shipName: json['ship_name'] as String? ?? 'Unknown Ship',
      cruiseLine: json['cruise_line_name'] as String? ?? 'Unknown',
      startDate: DateTime.parse(json['departure_date'] as String),
      endDate: DateTime.parse(json['arrival_date'] as String),
      durationNights: json['duration_nights'] as int? ?? 0,
      departurePort: json['departure_port'] as String? ?? 'Unknown',
      returnPort: json['arrival_port'] as String?,
      region: json['region'] as String?,
      priceFrom: (json['price_from'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }

  Cruise toCruise() => Cruise(
        id: id.toString(),
        name: cruiseName ?? '$shipName $durationNights-Night Cruise',
        cruiseLine: cruiseLine,
        shipName: shipName,
        startDate: startDate,
        endDate: endDate,
        durationNights: durationNights,
        departurePort: departurePort,
        returnPort: returnPort,
        region: region,
        apiId: id,
      );
}

/// Service for fetching cruise data from API
class CruiseApiService {
  final Dio _dio;

  CruiseApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              connectTimeout: AppConstants.connectionTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
            ));

  /// Get list of departure ports
  /// Endpoint: GET /api/cruises/reference/ports
  Future<List<PortDto>> getDeparturePorts({String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/cruises/reference/ports',
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = response.data;
      if (data != null && data['ports'] is List) {
        return (data['ports'] as List)
            .map((p) => PortDto.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('CruiseApiService: Failed to fetch ports: ${e.message}');
      return [];
    }
  }

  /// Search cruises by departure port and date range
  /// Endpoint: GET /api/cruises/search
  Future<List<CruiseSearchResultDto>> searchCruises({
    String? departurePort,
    int? departurePortId,
    DateTime? startDate,
    DateTime? endDate,
    int? minNights,
    int? maxNights,
    int page = 1,
    int limit = AppConstants.cruisesPerPage,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (departurePort != null) {
        params['departure_port'] = departurePort;
      }
      if (departurePortId != null) {
        params['departurePortId'] = departurePortId;
      }
      if (startDate != null) {
        params['date_from'] = startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        params['date_to'] = endDate.toIso8601String().split('T').first;
      }
      if (minNights != null) {
        params['duration_min'] = minNights;
      }
      if (maxNights != null) {
        params['duration_max'] = maxNights;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/cruises/search',
        queryParameters: params,
      );
      final data = response.data;
      if (data != null && data['data'] is List) {
        return (data['data'] as List)
            .map((c) => CruiseSearchResultDto.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('CruiseApiService: Failed to search cruises: ${e.message}');
      return [];
    }
  }

  /// Get cruise details by ID
  Future<Cruise?> getCruiseDetails(int cruiseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/cruises/$cruiseId');
      final data = response.data;
      if (data == null) return null;

      final dto = CruiseSearchResultDto.fromJson(data);
      return dto.toCruise();
    } on DioException catch (e) {
      debugPrint('CruiseApiService: Failed to fetch cruise $cruiseId: ${e.message}');
      return null;
    }
  }
}

