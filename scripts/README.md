# Build Scripts

This directory contains scripts for building llama.cpp native libraries for Android and iOS.

## Overview

The app uses `llama_cpp_dart` which requires compiled native libraries:
- **Android**: `libllama.so` (shared library)
- **iOS**: `llama.xcframework` (XCFramework with static libraries)

These scripts automate the compilation process and are used both locally and in CI/CD.

## Files

### `llama-version.txt`
Specifies the llama.cpp version (git commit/tag) to build.

**To update llama.cpp version:**
1. Edit this file and change the commit hash/tag
2. Commit the change
3. CI/CD will automatically rebuild libraries with the new version

### `build-llama-android.sh`
Builds llama.cpp for Android using Android NDK.

**Requirements:**
- Android NDK (set `ANDROID_NDK_HOME` or `ANDROID_NDK` environment variable)
- CMake
- Git

**Output:**
- `android/app/src/main/jniLibs/arm64-v8a/libllama.so`

**Usage:**
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk
bash scripts/build-llama-android.sh
```

### `build-llama-ios.sh`
Builds llama.cpp for iOS using Xcode toolchain.

**Requirements:**
- macOS
- Xcode Command Line Tools
- CMake
- Git

**Output:**
- `ios/Frameworks/llama.xcframework`

**Usage:**
```bash
bash scripts/build-llama-ios.sh
```

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/build.yml`) uses these scripts with caching:

1. **Cache Check**: Checks if libraries are already cached
2. **Build**: Runs build scripts if cache miss
3. **Verify**: Ensures libraries exist before Flutter build
4. **Cache Save**: Saves compiled libraries for future builds

**Cache Key**: `llama-{platform}-{hash of llama-version.txt}`

This means:
- ✅ Libraries are built once and reused (saves 5-10 minutes per build)
- ✅ Updating `llama-version.txt` invalidates cache and triggers rebuild
- ✅ Different caches for Android and iOS

## Local Development

### First Time Setup

**For Android:**
```bash
# Install Android NDK (if not already installed)
# Set environment variable
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/25.1.8937393

# Build library
bash scripts/build-llama-android.sh

# Verify
ls -lh android/app/src/main/jniLibs/arm64-v8a/libllama.so
```

**For iOS:**
```bash
# Build library (macOS only)
bash scripts/build-llama-ios.sh

# Verify
ls -lh ios/Frameworks/llama.xcframework

# Add to Xcode project (one-time setup)
# 1. Open ios/Runner.xcworkspace in Xcode
# 2. Drag llama.xcframework to "Frameworks, Libraries, and Embedded Content"
# 3. Set to "Embed & Sign"
```

### Updating llama.cpp

When a new version of llama.cpp is released:

1. **Update version file:**
   ```bash
   # Edit scripts/llama-version.txt
   # Change commit hash to new version
   ```

2. **Rebuild libraries:**
   ```bash
   # Android
   bash scripts/build-llama-android.sh
   
   # iOS (macOS only)
   bash scripts/build-llama-ios.sh
   ```

3. **Test locally:**
   ```bash
   flutter run
   ```

4. **Commit changes:**
   ```bash
   git add scripts/llama-version.txt
   git commit -m "Update llama.cpp to version X"
   git push
   ```

CI/CD will automatically rebuild libraries with the new version.

## Troubleshooting

### Android: NDK not found
```
Error: ANDROID_NDK_HOME or ANDROID_NDK environment variable not set
```

**Solution:**
```bash
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/25.1.8937393
# Or wherever your NDK is installed
```

### iOS: Not on macOS
```
Error: iOS build requires macOS
```

**Solution:** iOS builds can only be done on macOS. Use CI/CD or a Mac for iOS builds.

### Library not found during Flutter build

**Android:**
```bash
# Verify library exists
ls android/app/src/main/jniLibs/arm64-v8a/libllama.so

# If missing, rebuild
bash scripts/build-llama-android.sh
```

**iOS:**
```bash
# Verify framework exists
ls ios/Frameworks/llama.xcframework

# If missing, rebuild
bash scripts/build-llama-ios.sh

# Ensure it's added to Xcode project
```

### Build fails with CMake errors

**Solution:**
1. Ensure CMake is installed: `cmake --version`
2. Update CMake to latest version
3. Check llama.cpp build logs for specific errors

## Performance Notes

### Build Times
- **Android**: ~5-7 minutes (ARM64 only)
- **iOS**: ~8-10 minutes (device + simulator)

### Optimizations
- **Metal acceleration** (iOS): Enabled by default (`-DLLAMA_METAL=ON`)
- **Release build**: All builds use `-DCMAKE_BUILD_TYPE=Release`
- **Parallel compilation**: Uses all available CPU cores

### Cache Benefits
With caching enabled in CI/CD:
- **First build**: ~10 minutes (compile + cache)
- **Subsequent builds**: ~30 seconds (cache restore)
- **After version update**: ~10 minutes (recompile + cache)

## Resources

- **llama.cpp**: https://github.com/ggml-org/llama.cpp
- **llama_cpp_dart**: https://pub.dev/packages/llama_cpp_dart
- **Android NDK**: https://developer.android.com/ndk
- **Xcode**: https://developer.apple.com/xcode/

