// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelInfoImpl _$$ModelInfoImplFromJson(Map<String, dynamic> json) =>
    _$ModelInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      fileName: json['fileName'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      architecture: json['architecture'] as String,
      quantization: json['quantization'] as String,
      contextLength: (json['contextLength'] as num).toInt(),
      recommended: json['recommended'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ModelInfoImplToJson(_$ModelInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'fileName': instance.fileName,
      'sizeBytes': instance.sizeBytes,
      'architecture': instance.architecture,
      'quantization': instance.quantization,
      'contextLength': instance.contextLength,
      'recommended': instance.recommended,
      'tags': instance.tags,
    };

_$ModelManifestImpl _$$ModelManifestImplFromJson(Map<String, dynamic> json) =>
    _$ModelManifestImpl(
      version: json['version'] as String,
      lastUpdated: json['lastUpdated'] as String,
      models: (json['models'] as List<dynamic>)
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ModelManifestImplToJson(_$ModelManifestImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'lastUpdated': instance.lastUpdated,
      'models': instance.models.map((e) => e.toJson()).toList(),
    };

