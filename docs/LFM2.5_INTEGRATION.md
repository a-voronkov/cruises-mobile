# LFM2.5 Model Integration Guide

## Overview

This document describes the integration of **LiquidAI LFM2.5-1.2B-Instruct** model into the Cruises Mobile application.

## Model Specifications

- **Model**: LFM2.5-1.2B-Instruct
- **Parameters**: 1.17 billion
- **Format**: GGUF (quantized)
- **Quantization**: Q4_K_M (4-bit, medium quality)
- **Size**: ~700 MB
- **Context Length**: 32,768 tokens
- **Languages**: English, Arabic, Chinese, French, German, Japanese, Korean, Spanish
- **Architecture**: Hybrid (10 double-gated LIV convolution blocks + 6 GQA blocks)

## Key Features

✅ **Best-in-class performance**: Rivals much larger models  
✅ **Fast edge inference**: 82 tok/s on mobile NPU, 239 tok/s on AMD CPU  
✅ **Low memory**: Runs under 1GB of memory  
✅ **Day-one support**: llama.cpp, MLX, vLLM, ONNX  
✅ **Extended training**: 28T tokens pre-training  

## Chat Template Format

LFM2.5 uses a **ChatML-like format**:

```
<|startoftext|><|im_start|>system
You are a helpful assistant trained by Liquid AI.<|im_end|>
<|im_start|>user
What is C. elegans?<|im_end|>
<|im_start|>assistant
```

### Special Tokens

- `<|startoftext|>` - Beginning of sequence (BOS)
- `<|im_start|>` - Start of message
- `<|im_end|>` - End of message
- `<|tool_call_start|>` - Start of tool call (for function calling)
- `<|tool_call_end|>` - End of tool call

### Message Roles

- `system` - System instructions/context
- `user` - User messages
- `assistant` - AI assistant responses
- `tool` - Tool/function execution results

## Recommended Generation Parameters

Based on LiquidAI's recommendations:

```dart
temperature: 0.1        // Lower for more focused responses
top_k: 50              // Top-K sampling
top_p: 0.1             // Nucleus sampling
repetition_penalty: 1.05  // Prevent repetition
max_new_tokens: 512    // Maximum tokens to generate
```

## Implementation in Cruises Mobile

### 1. Model Storage

**Development**:
- Place model file in `models/` directory
- File: `lfm2.5-1.2b-instruct-q4_k_m.gguf`
- Excluded from git (see `.gitignore`)

**Production**:
- Downloaded from HuggingFace on first launch
- Stored in app documents directory
- Path: `{app_documents}/models/lfm2.5-1.2b-instruct-q4_k_m.gguf`

### 2. Chat Template Usage

```dart
import 'package:cruises_mobile/core/utils/chat_template.dart';

// Format messages for inference
final prompt = ChatTemplate.formatMessages(
  messages: conversationMessages,
  includeSystemPrompt: true,
  addGenerationPrompt: true,
);

// Format single user message
final prompt = ChatTemplate.formatUserMessage(
  'Plan a 7-day Mediterranean cruise',
);

// Extract response from model output
final cleanResponse = ChatTemplate.extractResponse(modelOutput);
```

### 3. Inference Configuration

```dart
// In lib/core/constants/app_constants.dart
static const int maxTokens = 512;
static const double temperature = 0.1;
static const int topK = 50;
static const double topP = 0.1;
static const double repetitionPenalty = 1.05;
static const int contextLength = 32768;
```

## Performance Expectations

### Mobile Devices

| Device | Platform | Speed | Memory |
|--------|----------|-------|--------|
| Snapdragon Gen4 | NPU | 82 tok/s | 0.9 GB |
| Snapdragon Gen4 | CPU | 70 tok/s | 719 MB |
| iPhone 15 Pro | CPU | ~60 tok/s | ~800 MB |

### Desktop/Laptop

| Device | Speed | Memory |
|--------|-------|--------|
| AMD CPU | 239 tok/s | ~1 GB |
| Apple M1/M2 | ~150 tok/s | ~1 GB |

## Use Cases

LFM2.5-1.2B-Instruct is recommended for:

✅ **Agentic tasks** - Multi-step planning and execution  
✅ **Data extraction** - Structured information extraction  
✅ **RAG (Retrieval-Augmented Generation)** - Context-aware responses  
✅ **Conversational AI** - Natural dialogue  
✅ **Travel planning** - Our primary use case  

❌ **Not recommended for**:
- Knowledge-intensive tasks (use larger models or RAG)
- Complex programming tasks

## Tool Use (Function Calling)

LFM2.5 supports function calling:

```dart
final tools = [
  {
    "name": "search_cruises",
    "description": "Search for available cruises",
    "parameters": {
      "type": "object",
      "properties": {
        "destination": {"type": "string"},
        "duration_days": {"type": "integer"}
      }
    }
  }
];

final prompt = ChatTemplate.formatMessagesWithTools(
  messages: messages,
  tools: tools,
);
```

Response format:
```
<|tool_call_start|>[search_cruises(destination="Mediterranean", duration_days=7)]<|tool_call_end|>
```

## Integration Steps

### Step 1: Download Model

**Option A: Manual (Development)**
```bash
# Download from HuggingFace
wget https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF/resolve/main/lfm2.5-1.2b-instruct-q4_k_m.gguf

# Move to models directory
mv lfm2.5-1.2b-instruct-q4_k_m.gguf models/
```

**Option B: Automatic (Production)**
- App downloads on first launch
- Shows progress to user
- Validates file integrity

### Step 2: Add llama.cpp Dependency

```yaml
# pubspec.yaml
dependencies:
  llama_cpp_dart: ^0.2.2  # LFM2/LFM2.5 supported via llama.cpp 4ffc47cb
  ffi: ^2.1.4  # Requires Dart 3.7.0+ (Flutter 3.38.6+)
```

### Step 3: Implement Inference

See `lib/features/chat/data/datasources/llm_inference_datasource.dart`

## Testing

### Unit Tests

```dart
test('Chat template formats correctly', () {
  final messages = [
    Message(
      id: '1',
      conversationId: 'test',
      content: 'Hello',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    ),
  ];

  final prompt = ChatTemplate.formatMessages(messages: messages);
  
  expect(prompt, contains('<|startoftext|>'));
  expect(prompt, contains('<|im_start|>system'));
  expect(prompt, contains('<|im_start|>user'));
  expect(prompt, contains('Hello'));
});
```

### Integration Tests

Test on real devices with actual model inference.

## Resources

- **Model Card**: https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct
- **GGUF Version**: https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF
- **Documentation**: https://liquid.ai/lfm/
- **llama.cpp**: https://github.com/ggerganov/llama.cpp
- **Paper**: LFM2 Technical Report (arXiv:2511.23404)

## Troubleshooting

### Model fails to load
- Check file integrity (MD5/SHA256)
- Verify sufficient memory (>1GB free)
- Check file permissions

### Slow inference
- Reduce context length
- Increase thread count
- Use NPU if available

### Poor quality responses
- Adjust temperature (try 0.1-0.3)
- Check prompt formatting
- Verify system prompt is included

## Next Steps

1. ✅ Configure model constants
2. ✅ Create chat template utility
3. ⏳ Implement llama.cpp integration
4. ⏳ Add model download service
5. ⏳ Implement inference engine
6. ⏳ Test on real devices

