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
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

/// Model-related failures
class ModelFailure extends Failure {
  const ModelFailure([String message = 'Model error occurred']) : super(message);
}

/// Model not found failure
class ModelNotFoundFailure extends ModelFailure {
  const ModelNotFoundFailure([String message = 'Model not found']) : super(message);
}

/// Model download failure
class ModelDownloadFailure extends ModelFailure {
  const ModelDownloadFailure([String message = 'Failed to download model']) : super(message);
}

/// Model loading failure
class ModelLoadFailure extends ModelFailure {
  const ModelLoadFailure([String message = 'Failed to load model']) : super(message);
}

/// Inference failure
class InferenceFailure extends Failure {
  const InferenceFailure([String message = 'Inference failed']) : super(message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation failed']) : super(message);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied']) : super(message);
}

/// Storage failure
class StorageFailure extends Failure {
  const StorageFailure([String message = 'Storage error occurred']) : super(message);
}

/// File system failure
class FileSystemFailure extends Failure {
  const FileSystemFailure([String message = 'File system error occurred']) : super(message);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred']) : super(message);
}

