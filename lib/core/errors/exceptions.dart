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
  ServerException([super.message = 'Server error', super.originalError]);
}

/// Cache exception
class CacheException extends AppException {
  CacheException([super.message = 'Cache error', super.originalError]);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException([super.message = 'Network error', super.originalError]);
}

/// Model exception
class ModelException extends AppException {
  ModelException([super.message = 'Model error', super.originalError]);
}

/// Model not found exception
class ModelNotFoundException extends ModelException {
  ModelNotFoundException([
    super.message = 'Model not found',
    super.originalError,
  ]);
}

/// Model download exception
class ModelDownloadException extends ModelException {
  ModelDownloadException([
    super.message = 'Model download failed',
    super.originalError,
  ]);
}

/// Model load exception
class ModelLoadException extends ModelException {
  ModelLoadException([
    super.message = 'Model load failed',
    super.originalError,
  ]);
}

/// Inference exception
class InferenceException extends AppException {
  InferenceException([super.message = 'Inference failed', super.originalError]);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException([
    super.message = 'Validation failed',
    super.originalError,
  ]);
}

/// Permission exception
class PermissionException extends AppException {
  PermissionException([
    super.message = 'Permission denied',
    super.originalError,
  ]);
}

/// Storage exception
class StorageException extends AppException {
  StorageException([super.message = 'Storage error', super.originalError]);
}

/// File system exception
class FileSystemException extends AppException {
  FileSystemException([
    super.message = 'File system error',
    super.originalError,
  ]);
}

