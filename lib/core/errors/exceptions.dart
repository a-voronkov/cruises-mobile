/// Base exception class for data layer
class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, [this.originalError]);

  @override
  String toString() => 'AppException: $message';
}

/// Server exception
class ServerException extends AppException {
  ServerException([String message = 'Server error', dynamic error])
      : super(message, error);
}

/// Cache exception
class CacheException extends AppException {
  CacheException([String message = 'Cache error', dynamic error])
      : super(message, error);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException([String message = 'Network error', dynamic error])
      : super(message, error);
}

/// Model exception
class ModelException extends AppException {
  ModelException([String message = 'Model error', dynamic error])
      : super(message, error);
}

/// Model not found exception
class ModelNotFoundException extends ModelException {
  ModelNotFoundException([String message = 'Model not found', dynamic error])
      : super(message, error);
}

/// Model download exception
class ModelDownloadException extends ModelException {
  ModelDownloadException([String message = 'Model download failed', dynamic error])
      : super(message, error);
}

/// Model load exception
class ModelLoadException extends ModelException {
  ModelLoadException([String message = 'Model load failed', dynamic error])
      : super(message, error);
}

/// Inference exception
class InferenceException extends AppException {
  InferenceException([String message = 'Inference failed', dynamic error])
      : super(message, error);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException([String message = 'Validation failed', dynamic error])
      : super(message, error);
}

/// Permission exception
class PermissionException extends AppException {
  PermissionException([String message = 'Permission denied', dynamic error])
      : super(message, error);
}

/// Storage exception
class StorageException extends AppException {
  StorageException([String message = 'Storage error', dynamic error])
      : super(message, error);
}

/// File system exception
class FileSystemException extends AppException {
  FileSystemException([String message = 'File system error', dynamic error])
      : super(message, error);
}

