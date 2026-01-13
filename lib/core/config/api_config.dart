/// API configuration
/// 
/// This file contains API keys and configuration.
/// DO NOT commit this file with real API keys!
class ApiConfig {
  ApiConfig._();

  // HuggingFace API key
  // This will be replaced during CI build with the actual key from secrets
  static const String huggingFaceApiKey = String.fromEnvironment(
    'HF_TOKEN',
    defaultValue: '',
  );

  /// Check if API key is configured
  static bool get isConfigured => huggingFaceApiKey.isNotEmpty;
}

