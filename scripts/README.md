# Utility Scripts

This directory contains utility scripts for the project.

## Overview

The app uses ONNX Runtime via `fonnx` package which provides pre-built binaries for all platforms.
No native library compilation is required.

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

- **FONNX**: https://pub.dev/packages/fonnx
- **ONNX Runtime**: https://onnxruntime.ai/
- **HuggingFace**: https://huggingface.co/

