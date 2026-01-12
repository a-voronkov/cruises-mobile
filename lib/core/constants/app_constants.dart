/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Cruises Assistant';
  static const String appVersion = '1.0.0';

  // Model Configuration - LiquidAI LFM2.5-1.2B-Instruct
  static const String modelName = 'LFM2.5-1.2B-Instruct';
  static const String modelVersion = 'GGUF';
  static const String modelFileName = 'lfm2.5-1.2b-instruct-q4_k_m.gguf';

  // Model Server Configuration
  static const String modelServerBaseUrl = 'https://cruises.voronkov.club/models';

  // Model Manifest URL (for fetching available models list)
  static const String modelManifestUrl = '$modelServerBaseUrl/manifest.json';

  // Model Download URL (custom server)
  static const String modelDownloadUrl = '$modelServerBaseUrl/$modelFileName';

  // Model size in bytes (approximate - Q4_K_M quantization ~700MB)
  static const int modelSizeBytes = 700000000; // ~700MB

  // Model local path (relative to app documents directory)
  static const String modelLocalPath = 'models/$modelFileName';

  // Storage Keys
  static const String modelStorageKey = 'llm_model';
  static const String conversationsBoxKey = 'conversations';
  static const String messagesBoxKey = 'messages';
  static const String settingsBoxKey = 'settings';

  // Settings Keys
  static const String themeKey = 'theme_mode';
  static const String modelDownloadedKey = 'model_downloaded';
  static const String firstLaunchKey = 'first_launch';

  // LLM Configuration - LFM2.5 Recommended Settings
  static const int maxTokens = 512; // Max new tokens to generate
  static const double temperature = 0.1; // Lower for more focused responses
  static const int topK = 50;
  static const double topP = 0.1;
  static const double repetitionPenalty = 1.05;
  // Context length reduced for mobile devices (32K causes OOM on <16GB RAM)
  static const int contextLength = 2048;
  static const int numThreads = 4; // Will be adjusted based on device

  // Chat Template - LFM2.5 uses ChatML-like format
  static const String systemPrompt =
      'You are a helpful travel assistant trained by Liquid AI. '
      'You help users plan their cruise vacations and travel itineraries. '
      'Provide detailed, accurate, and friendly advice.';

  // Special tokens for LFM2.5
  static const String bosToken = '<|startoftext|>';
  static const String imStartToken = '<|im_start|>';
  static const String imEndToken = '<|im_end|>';
  static const String toolCallStartToken = '<|tool_call_start|>';
  static const String toolCallEndToken = '<|tool_call_end|>';

  // UI Configuration
  static const int maxMessageLength = 4000;
  static const Duration typingIndicatorDelay = Duration(milliseconds: 500);
  static const Duration messageAnimationDuration = Duration(milliseconds: 300);

  // File Upload Limits
  static const int maxImageSizeMB = 10;
  static const int maxFileSizeMB = 20;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedFileExtensions = ['pdf', 'txt', 'doc', 'docx'];

  // Network Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // API Configuration
  static const String apiBaseUrl = 'https://cruises.voronkov.club/api';

  // Pagination
  static const int messagesPerPage = 50;
  static const int conversationsPerPage = 20;
  static const int cruisesPerPage = 20;
}

