# Utility Scripts

This directory contains utility scripts for the project.

## Overview

The app uses ONNX Runtime via `onnxruntime` package which provides pre-built binaries for all platforms.
No native library compilation is required.

**Note:** ONNX Runtime integration for text generation requires additional implementation:
- Tokenizer (convert text to input IDs)
- Input tensor preparation
- Iterative generation loop with KV-cache management
- Token decoding (convert output IDs back to text)

Consider using HuggingFace Optimum to export models in the correct format for ONNX Runtime.

## Files

### `increment-version.sh`

Automatically increments the build number in `pubspec.yaml` during commits.

**Usage:**

This script is called automatically by the git pre-commit hook.

**Manual usage:**

```bash
bash scripts/increment-version.sh
```

### `setup-hooks.sh`

Sets up git hooks for the project.

**Usage:**

```bash
bash scripts/setup-hooks.sh
```

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/build.yml`) uses FONNX which provides pre-built ONNX Runtime binaries.

No compilation step is required - the workflow simply:

1. **Install dependencies**: `flutter pub get`
2. **Build app**: `flutter build apk/ipa`
3. **Upload artifacts**: APK/IPA files

## Resources

- **ONNX Runtime Package**: <https://pub.dev/packages/onnxruntime>
- **ONNX Runtime**: <https://onnxruntime.ai/>
- **HuggingFace**: <https://huggingface.co/>
- **HuggingFace Optimum**: <https://huggingface.co/docs/optimum/>

