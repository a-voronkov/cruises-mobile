# ONNX Runtime Integration Guide

## Overview

This app now uses **ONNX Runtime** for local inference instead of llama.cpp. ONNX Runtime provides better cross-platform support and access to a wider range of models from HuggingFace.

## Current Status

✅ **Completed:**
- ONNX Runtime package integrated (`onnxruntime: ^1.19.2`)
- Basic session initialization
- Model loading from local storage

⚠️ **Requires Implementation:**
- Tokenizer (convert text to input IDs)
- Input tensor preparation
- Iterative text generation with KV-cache
- Token decoding (convert output IDs back to text)

## Why ONNX Runtime?

**Advantages:**
- ✅ Wide model support (HuggingFace, PyTorch, TensorFlow)
- ✅ Cross-platform (Android, iOS, Windows, macOS, Linux)
- ✅ Hardware acceleration (CPU, GPU, NPU)
- ✅ Optimized inference performance
- ✅ Active development and support

**Challenges:**
- ❌ Requires manual tokenizer implementation
- ❌ More complex than llama.cpp for text generation
- ❌ Need to manage KV-cache manually

## Getting ONNX Models

### Option 1: HuggingFace Hub

Many models on HuggingFace are available in ONNX format:

```bash
# Example: Download ONNX model
git clone https://huggingface.co/onnx-community/Llama-3.2-1B-Instruct-ONNX
```

### Option 2: Export with Optimum

Use HuggingFace Optimum to export PyTorch models to ONNX:

```bash
pip install optimum[exporters]

# Export model to ONNX
optimum-cli export onnx \
  --model meta-llama/Llama-3.2-1B-Instruct \
  --task text-generation-with-past \
  llama-3.2-onnx/
```

## Implementation Roadmap

### Phase 1: Tokenizer Integration

**Option A: Use HuggingFace Tokenizers (Recommended)**

```yaml
# pubspec.yaml
dependencies:
  tokenizers: ^0.4.0  # Dart bindings for HF tokenizers
```

**Option B: Implement Custom Tokenizer**

Create a simple BPE tokenizer for your specific model.

### Phase 2: Input Preparation

```dart
// Example pseudo-code
Future<Map<String, OrtValueTensor>> prepareInputs(String prompt) async {
  // 1. Tokenize
  final tokens = await tokenizer.encode(prompt);
  
  // 2. Create input tensors
  final inputIds = OrtValueTensor.createTensorWithDataList(
    [tokens],
    [1, tokens.length],
  );
  
  final attentionMask = OrtValueTensor.createTensorWithDataList(
    [List.filled(tokens.length, 1)],
    [1, tokens.length],
  );
  
  return {
    'input_ids': inputIds,
    'attention_mask': attentionMask,
  };
}
```

### Phase 3: Generation Loop

```dart
Future<String> generate(String prompt, {int maxTokens = 100}) async {
  final inputs = await prepareInputs(prompt);
  final generatedTokens = <int>[];
  
  for (int i = 0; i < maxTokens; i++) {
    // Run inference
    final outputs = await session.run(null, inputs);
    
    // Get logits and sample next token
    final logits = outputs[0];
    final nextToken = sampleToken(logits);
    
    if (nextToken == eosTokenId) break;
    
    generatedTokens.add(nextToken);
    
    // Update inputs for next iteration
    inputs = updateInputs(inputs, nextToken);
  }
  
  // Decode tokens to text
  return await tokenizer.decode(generatedTokens);
}
```

### Phase 4: Streaming Support

Implement streaming by yielding tokens as they're generated.

## Resources

- **ONNX Runtime Docs**: <https://onnxruntime.ai/docs/>
- **HuggingFace Optimum**: <https://huggingface.co/docs/optimum/>
- **ONNX Models**: <https://huggingface.co/models?library=onnx>
- **Tokenizers Package**: <https://pub.dev/packages/tokenizers>

## Migration from llama.cpp

If you previously used llama.cpp (GGUF models), you'll need to:

1. Convert GGUF models to ONNX format (or download ONNX versions)
2. Implement tokenizer (llama.cpp handled this automatically)
3. Update model download logic to fetch ONNX files
4. Test thoroughly on target devices

## Performance Tips

1. **Use quantized models** (INT8, INT4) for mobile devices
2. **Enable hardware acceleration** (GPU/NPU) when available
3. **Optimize KV-cache** management for memory efficiency
4. **Profile on real devices** to identify bottlenecks

## Next Steps

1. Choose a tokenizer solution (HF tokenizers recommended)
2. Implement input preparation logic
3. Create generation loop with sampling
4. Add streaming support
5. Test with various models and prompts
6. Optimize for mobile performance

