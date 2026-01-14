# Local LLM Inference Guide

This guide explains how to use local LLM inference in the Cruises Mobile app using llama.cpp.

## Overview

The app now supports two inference modes:

1. **Cloud Mode** (default) - Uses HuggingFace Inference API
2. **Local Mode** - Uses llama.cpp for on-device inference

## Prerequisites

### 1. GGUF Model File

You need a GGUF format model file. Recommended models:

- **Phi-3-mini-4k-instruct-q4.gguf** (~2.3 GB) - Good balance of size and quality
- **TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf** (~669 MB) - Smallest, fastest
- **Llama-2-7b-chat.Q4_K_M.gguf** (~4 GB) - Higher quality

Download from:
- [HuggingFace GGUF Models](https://huggingface.co/models?search=gguf)
- [TheBloke's GGUF Collection](https://huggingface.co/TheBloke)

### 2. llama.cpp Shared Library

The app requires a compiled llama.cpp shared library for your platform:

- **Android**: `libllama.so` (ARM64)
- **iOS**: `libllama.dylib` (ARM64)
- **Windows**: `llama.dll`
- **macOS**: `libllama.dylib`
- **Linux**: `libllama.so`

## Setup Instructions

### Step 1: Build llama.cpp Library

#### For Android (ARM64):

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

# Build for Android ARM64
mkdir build-android
cd build-android
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DBUILD_SHARED_LIBS=ON
make -j4

# Copy to Flutter project
cp libllama.so /path/to/cruises-mobile/android/app/src/main/jniLibs/arm64-v8a/
```

#### For iOS:

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

# Build for iOS
mkdir build-ios
cd build-ios
cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_SHARED_LIBS=ON
make -j4

# Copy to Flutter project
cp libllama.dylib /path/to/cruises-mobile/ios/
```

### Step 2: Add Model File

1. Place your GGUF model file in the app's documents directory:
   - Android: `/data/data/com.example.cruises_mobile/files/models/`
   - iOS: `~/Library/Application Support/models/`

2. Or use the app's model downloader (if implemented)

### Step 3: Initialize Local Inference

```dart
import 'package:cruises_mobile/core/services/ai_service.dart';

final aiService = AIService();

// Initialize with local model
final success = await aiService.initializeLocal(
  modelFileName: 'phi-3-mini-4k-instruct-q4.gguf',
  onProgress: (progress) {
    print('Loading: ${(progress * 100).toStringAsFixed(0)}%');
  },
);

if (success) {
  print('Local inference ready!');
} else {
  print('Failed to initialize local inference');
}
```

### Step 4: Generate Text

```dart
// Non-streaming generation
final response = await aiService.generate(
  prompt: 'What is the capital of France?',
  maxTokens: 100,
  temperature: 0.7,
);
print(response);

// Streaming generation
final messages = [
  {'role': 'user', 'content': 'Tell me a joke'},
];

await for (final chunk in aiService.generateStream(messages: messages)) {
  print(chunk); // Print each token as it's generated
}
```

## Switching Between Modes

```dart
// Check current mode
if (aiService.isLocal) {
  print('Using local inference');
} else {
  print('Using cloud inference');
}

// Switch to cloud mode
await aiService.initialize(
  apiKey: 'your-hf-api-key',
  modelId: 'meta-llama/Llama-2-7b-chat-hf',
);

// Switch back to local mode
await aiService.initializeLocal(
  modelFileName: 'model.gguf',
);
```

## Performance Tips

1. **Model Size**: Smaller models (1-3B parameters) work better on mobile
2. **Quantization**: Q4_K_M provides good balance of quality and speed
3. **Context Size**: Default is 2048 tokens, reduce if memory is limited
4. **GPU Acceleration**: Currently CPU-only, GPU support coming soon

## Troubleshooting

### Model Not Found
- Ensure the model file is in the correct directory
- Check file permissions
- Verify the filename matches exactly

### Out of Memory
- Use a smaller model (e.g., TinyLlama instead of Llama-2-7b)
- Reduce context size in `LocalInferenceService`
- Close other apps to free memory

### Slow Generation
- Use a more quantized model (Q3 or Q2 instead of Q4)
- Reduce max_tokens
- Consider using cloud mode for complex queries

## Next Steps

- [ ] Add model downloader UI
- [ ] Implement GPU acceleration (Metal for iOS, Vulkan for Android)
- [ ] Add model management (list, delete, switch)
- [ ] Optimize memory usage
- [ ] Add benchmarking tools

