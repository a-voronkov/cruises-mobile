# LLM Integration Guide

This document describes how to integrate the HY-MT1.5-1.8B-GGUF model into the Cruises Mobile application.

## Overview

The application uses a locally-running Large Language Model (LLM) for AI-powered travel assistance. The model runs entirely on-device, ensuring privacy and offline functionality.

## Model Specifications

- **Model**: HY-MT1.5-1.8B-GGUF
- **Quantization**: Q4_K_M (4-bit quantization, medium quality)
- **Size**: ~1.2 GB
- **Format**: GGUF (GPT-Generated Unified Format)
- **Runtime**: llama.cpp via FFI

## Architecture

### Components

1. **Model Download Service**
   - Downloads model from server on first launch
   - Shows progress to user
   - Validates downloaded file
   - Stores in app documents directory

2. **Model Storage Service**
   - Manages model file location
   - Checks model availability
   - Handles model deletion/updates

3. **Model Inference Service**
   - Loads model into memory
   - Processes user prompts
   - Streams responses
   - Manages context window

## Implementation Steps

### Step 1: Add llama.cpp Bindings

Since there's no mature Flutter package for GGUF models, we'll use FFI to call llama.cpp directly.

#### Option A: Use flutter_llama (if available)

```yaml
dependencies:
  flutter_llama: ^0.1.0  # Check for latest version
```

#### Option B: Build Custom FFI Bindings

1. **Add llama.cpp as a native dependency**

Create `ios/llama.cpp/` and `android/llama.cpp/` directories with llama.cpp source.

2. **Create FFI bindings**

```dart
// lib/core/llm/llama_bindings.dart
import 'dart:ffi';
import 'dart:io';

class LlamaBindings {
  late final DynamicLibrary _lib;
  
  LlamaBindings() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libllama.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    }
  }
  
  // Define FFI functions here
}
```

### Step 2: Implement Model Download

```dart
// lib/features/model_management/data/datasources/model_download_datasource.dart
class ModelDownloadDataSourceImpl implements ModelDownloadDataSource {
  final Dio dio;
  final String savePath;
  
  @override
  Future<void> downloadModel({
    required String url,
    required Function(double) onProgress,
  }) async {
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );
  }
}
```

### Step 3: Implement Model Loading

```dart
// lib/features/model_management/data/datasources/model_storage_datasource.dart
class ModelStorageDataSourceImpl implements ModelStorageDataSource {
  @override
  Future<bool> isModelAvailable() async {
    final file = File(modelPath);
    return file.exists();
  }
  
  @override
  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/${AppConstants.modelFileName}';
  }
}
```

### Step 4: Implement Inference

```dart
// lib/features/chat/data/datasources/llm_inference_datasource.dart
class LLMInferenceDataSourceImpl implements LLMInferenceDataSource {
  late final LlamaModel _model;
  
  @override
  Future<void> loadModel(String path) async {
    _model = await LlamaModel.load(
      path,
      contextLength: AppConstants.contextLength,
      numThreads: AppConstants.numThreads,
    );
  }
  
  @override
  Stream<String> generateResponse(String prompt) async* {
    final stream = _model.generate(
      prompt,
      maxTokens: AppConstants.maxTokens,
      temperature: AppConstants.temperature,
    );
    
    await for (final token in stream) {
      yield token;
    }
  }
}
```

## Model Hosting

### Server Setup

1. **Upload model to your server**
   ```bash
   scp hy-mt1.5-1.8b-q4_k_m.gguf user@your-server.com:/var/www/models/
   ```

2. **Configure web server (nginx example)**
   ```nginx
   location /models/ {
       alias /var/www/models/;
       add_header Access-Control-Allow-Origin *;
       add_header Content-Type application/octet-stream;
   }
   ```

3. **Update URL in app**
   ```dart
   // lib/core/constants/app_constants.dart
   static const String modelDownloadUrl = 
       'https://your-server.com/models/hy-mt1.5-1.8b-q4_k_m.gguf';
   ```

## Performance Optimization

### Memory Management

```dart
// Unload model when app goes to background
class ModelLifecycleManager {
  void onAppPaused() {
    _model?.unload();
  }
  
  void onAppResumed() {
    _model?.reload();
  }
}
```

### Thread Configuration

```dart
// Adjust based on device capabilities
int getOptimalThreadCount() {
  final cores = Platform.numberOfProcessors;
  return (cores * 0.75).round(); // Use 75% of cores
}
```

### Context Window Management

```dart
// Trim context when it gets too long
String trimContext(List<Message> messages) {
  const maxContextTokens = 3000;
  // Keep system prompt + recent messages
  // Implement token counting and trimming
}
```

## Testing

### Unit Tests

```dart
test('Model downloads successfully', () async {
  final dataSource = ModelDownloadDataSourceImpl(dio, savePath);
  await dataSource.downloadModel(
    url: testUrl,
    onProgress: (progress) => print(progress),
  );
  expect(File(savePath).existsSync(), true);
});
```

### Integration Tests

```dart
testWidgets('Model setup flow works', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.byType(ModelSetupPage), findsOneWidget);
  
  await tester.tap(find.text('Download AI Model'));
  await tester.pumpAndSettle();
  
  // Verify navigation to chat page after download
  expect(find.byType(ChatPage), findsOneWidget);
});
```

## Troubleshooting

### Common Issues

1. **Model fails to load**
   - Check file integrity (MD5/SHA256 hash)
   - Verify sufficient memory available
   - Check file permissions

2. **Inference is slow**
   - Reduce context length
   - Increase thread count
   - Use smaller quantization (Q4 → Q3)

3. **App crashes on model load**
   - Reduce context length
   - Check available RAM
   - Use background isolate for loading

### Debug Logging

```dart
// Enable verbose logging
class LLMLogger {
  static void log(String message) {
    if (kDebugMode) {
      print('[LLM] $message');
    }
  }
}
```

## Future Enhancements

- [ ] Support multiple models
- [ ] Model quantization options
- [ ] Cloud fallback for complex queries
- [ ] Model fine-tuning for travel domain
- [ ] Caching frequent responses
- [ ] Streaming optimization

## Resources

- llama.cpp: https://github.com/ggerganov/llama.cpp
- GGUF format: https://github.com/ggerganov/ggml/blob/master/docs/gguf.md
- Model optimization: https://huggingface.co/docs/transformers/main/en/quantization

