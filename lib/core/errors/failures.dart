import 'package:equatable/equatable.dart';

/// Base class for all failures in the domain layer
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

/// Model-related failures
class ModelFailure extends Failure {
  const ModelFailure([super.message = 'Model error occurred']);
}

/// Model not found failure
class ModelNotFoundFailure extends ModelFailure {
  const ModelNotFoundFailure([super.message = 'Model not found']);
}

/// Model download failure
class ModelDownloadFailure extends ModelFailure {
  const ModelDownloadFailure([super.message = 'Failed to download model']);
}

/// Model loading failure
class ModelLoadFailure extends ModelFailure {
  const ModelLoadFailure([super.message = 'Failed to load model']);
}

/// Inference failure
class InferenceFailure extends Failure {
  const InferenceFailure([super.message = 'Inference failed']);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

/// Storage failure
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error occurred']);
}

/// File system failure
class FileSystemFailure extends Failure {
  const FileSystemFailure([super.message = 'File system error occurred']);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}

