// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) {
  return _ModelInfo.fromJson(json);
}

/// @nodoc
mixin _$ModelInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  String get architecture => throw _privateConstructorUsedError;
  String get quantization => throw _privateConstructorUsedError;
  int get contextLength => throw _privateConstructorUsedError;
  bool get recommended => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ModelInfoCopyWith<ModelInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelInfoCopyWith<$Res> {
  factory $ModelInfoCopyWith(ModelInfo value, $Res Function(ModelInfo) then) = _$ModelInfoCopyWithImpl<$Res, ModelInfo>;
  @useResult
  $Res call({String id, String name, String description, String fileName, int sizeBytes, String architecture, String quantization, int contextLength, bool recommended, List<String> tags});
}

/// @nodoc
class _$ModelInfoCopyWithImpl<$Res, $Val extends ModelInfo> implements $ModelInfoCopyWith<$Res> {
  _$ModelInfoCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? description = null, Object? fileName = null, Object? sizeBytes = null, Object? architecture = null, Object? quantization = null, Object? contextLength = null, Object? recommended = null, Object? tags = null}) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      name: null == name ? _value.name : name as String,
      description: null == description ? _value.description : description as String,
      fileName: null == fileName ? _value.fileName : fileName as String,
      sizeBytes: null == sizeBytes ? _value.sizeBytes : sizeBytes as int,
      architecture: null == architecture ? _value.architecture : architecture as String,
      quantization: null == quantization ? _value.quantization : quantization as String,
      contextLength: null == contextLength ? _value.contextLength : contextLength as int,
      recommended: null == recommended ? _value.recommended : recommended as bool,
      tags: null == tags ? _value.tags : tags as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelInfoImplCopyWith<$Res> implements $ModelInfoCopyWith<$Res> {
  factory _$$ModelInfoImplCopyWith(_$ModelInfoImpl value, $Res Function(_$ModelInfoImpl) then) = __$$ModelInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String description, String fileName, int sizeBytes, String architecture, String quantization, int contextLength, bool recommended, List<String> tags});
}

/// @nodoc
class __$$ModelInfoImplCopyWithImpl<$Res> extends _$ModelInfoCopyWithImpl<$Res, _$ModelInfoImpl> implements _$$ModelInfoImplCopyWith<$Res> {
  __$$ModelInfoImplCopyWithImpl(_$ModelInfoImpl _value, $Res Function(_$ModelInfoImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? description = null, Object? fileName = null, Object? sizeBytes = null, Object? architecture = null, Object? quantization = null, Object? contextLength = null, Object? recommended = null, Object? tags = null}) {
    return _then(_$ModelInfoImpl(
      id: null == id ? _value.id : id as String,
      name: null == name ? _value.name : name as String,
      description: null == description ? _value.description : description as String,
      fileName: null == fileName ? _value.fileName : fileName as String,
      sizeBytes: null == sizeBytes ? _value.sizeBytes : sizeBytes as int,
      architecture: null == architecture ? _value.architecture : architecture as String,
      quantization: null == quantization ? _value.quantization : quantization as String,
      contextLength: null == contextLength ? _value.contextLength : contextLength as int,
      recommended: null == recommended ? _value.recommended : recommended as bool,
      tags: null == tags ? _value._tags : tags as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelInfoImpl implements _ModelInfo {
  const _$ModelInfoImpl({required this.id, required this.name, required this.description, required this.fileName, required this.sizeBytes, required this.architecture, required this.quantization, required this.contextLength, this.recommended = false, final List<String> tags = const []}) : _tags = tags;

  factory _$ModelInfoImpl.fromJson(Map<String, dynamic> json) => _$$ModelInfoImplFromJson(json);

  @override final String id;
  @override final String name;
  @override final String description;
  @override final String fileName;
  @override final int sizeBytes;
  @override final String architecture;
  @override final String quantization;
  @override final int contextLength;
  @override @JsonKey() final bool recommended;
  final List<String> _tags;
  @override @JsonKey() List<String> get tags => List.unmodifiable(_tags);

  @override
  String toString() => 'ModelInfo(id: $id, name: $name, description: $description, fileName: $fileName, sizeBytes: $sizeBytes, architecture: $architecture, quantization: $quantization, contextLength: $contextLength, recommended: $recommended, tags: $tags)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType && other is _$ModelInfoImpl && (identical(other.id, id) || other.id == id) && (identical(other.name, name) || other.name == name) && (identical(other.description, description) || other.description == description) && (identical(other.fileName, fileName) || other.fileName == fileName) && (identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes) && (identical(other.architecture, architecture) || other.architecture == architecture) && (identical(other.quantization, quantization) || other.quantization == quantization) && (identical(other.contextLength, contextLength) || other.contextLength == contextLength) && (identical(other.recommended, recommended) || other.recommended == recommended) && const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, fileName, sizeBytes, architecture, quantization, contextLength, recommended, const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelInfoImplCopyWith<_$ModelInfoImpl> get copyWith => __$$ModelInfoImplCopyWithImpl<_$ModelInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() => _$$ModelInfoImplToJson(this);
}

abstract class _ModelInfo implements ModelInfo {
  const factory _ModelInfo({required final String id, required final String name, required final String description, required final String fileName, required final int sizeBytes, required final String architecture, required final String quantization, required final int contextLength, final bool recommended, final List<String> tags}) = _$ModelInfoImpl;
  factory _ModelInfo.fromJson(Map<String, dynamic> json) = _$ModelInfoImpl.fromJson;
  @override String get id; @override String get name; @override String get description; @override String get fileName; @override int get sizeBytes; @override String get architecture; @override String get quantization; @override int get contextLength; @override bool get recommended; @override List<String> get tags;
  @override @JsonKey(ignore: true) _$$ModelInfoImplCopyWith<_$ModelInfoImpl> get copyWith => throw _privateConstructorUsedError;
}




ModelManifest _$ModelManifestFromJson(Map<String, dynamic> json) {
  return _ModelManifest.fromJson(json);
}

/// @nodoc
mixin _$ModelManifest {
  String get version => throw _privateConstructorUsedError;
  String get lastUpdated => throw _privateConstructorUsedError;
  List<ModelInfo> get models => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ModelManifestCopyWith<ModelManifest> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelManifestCopyWith<$Res> {
  factory $ModelManifestCopyWith(ModelManifest value, $Res Function(ModelManifest) then) = _$ModelManifestCopyWithImpl<$Res, ModelManifest>;
  @useResult
  $Res call({String version, String lastUpdated, List<ModelInfo> models});
}

/// @nodoc
class _$ModelManifestCopyWithImpl<$Res, $Val extends ModelManifest> implements $ModelManifestCopyWith<$Res> {
  _$ModelManifestCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? version = null, Object? lastUpdated = null, Object? models = null}) {
    return _then(_value.copyWith(
      version: null == version ? _value.version : version as String,
      lastUpdated: null == lastUpdated ? _value.lastUpdated : lastUpdated as String,
      models: null == models ? _value.models : models as List<ModelInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelManifestImplCopyWith<$Res> implements $ModelManifestCopyWith<$Res> {
  factory _$$ModelManifestImplCopyWith(_$ModelManifestImpl value, $Res Function(_$ModelManifestImpl) then) = __$$ModelManifestImplCopyWithImpl<$Res>;
  @override @useResult $Res call({String version, String lastUpdated, List<ModelInfo> models});
}

/// @nodoc
class __$$ModelManifestImplCopyWithImpl<$Res> extends _$ModelManifestCopyWithImpl<$Res, _$ModelManifestImpl> implements _$$ModelManifestImplCopyWith<$Res> {
  __$$ModelManifestImplCopyWithImpl(_$ModelManifestImpl _value, $Res Function(_$ModelManifestImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? version = null, Object? lastUpdated = null, Object? models = null}) {
    return _then(_$ModelManifestImpl(
      version: null == version ? _value.version : version as String,
      lastUpdated: null == lastUpdated ? _value.lastUpdated : lastUpdated as String,
      models: null == models ? _value._models : models as List<ModelInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelManifestImpl implements _ModelManifest {
  const _$ModelManifestImpl({required this.version, required this.lastUpdated, required final List<ModelInfo> models}) : _models = models;

  factory _$ModelManifestImpl.fromJson(Map<String, dynamic> json) => _$$ModelManifestImplFromJson(json);

  @override final String version;
  @override final String lastUpdated;
  final List<ModelInfo> _models;
  @override List<ModelInfo> get models => List.unmodifiable(_models);

  @override
  String toString() => 'ModelManifest(version: $version, lastUpdated: $lastUpdated, models: $models)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType && other is _$ModelManifestImpl && (identical(other.version, version) || other.version == version) && (identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated) && const DeepCollectionEquality().equals(other._models, _models));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, version, lastUpdated, const DeepCollectionEquality().hash(_models));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelManifestImplCopyWith<_$ModelManifestImpl> get copyWith => __$$ModelManifestImplCopyWithImpl<_$ModelManifestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() => _$$ModelManifestImplToJson(this);
}

abstract class _ModelManifest implements ModelManifest {
  const factory _ModelManifest({required final String version, required final String lastUpdated, required final List<ModelInfo> models}) = _$ModelManifestImpl;
  factory _ModelManifest.fromJson(Map<String, dynamic> json) = _$ModelManifestImpl.fromJson;
  @override String get version; @override String get lastUpdated; @override List<ModelInfo> get models;
  @override @JsonKey(ignore: true) _$$ModelManifestImplCopyWith<_$ModelManifestImpl> get copyWith => throw _privateConstructorUsedError;
}