# CI/CD Setup for llama.cpp Integration

This document explains how llama.cpp native libraries are built and cached in the CI/CD pipeline.

## Overview

The app requires compiled llama.cpp libraries for both Android and iOS. The CI/CD pipeline automatically builds these libraries with intelligent caching to minimize build times.

## Architecture

### Build Process

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │   Android    │      │     iOS      │                     │
│  │    Build     │      │    Build     │                     │
│  └──────┬───────┘      └──────┬───────┘                     │
│         │                     │                              │
│         ▼                     ▼                              │
│  ┌──────────────────────────────────────┐                   │
│  │   Check Cache (llama-version.txt)    │                   │
│  └──────┬───────────────────────┬───────┘                   │
│         │                       │                            │
│    Cache Hit              Cache Miss                         │
│         │                       │                            │
│         ▼                       ▼                            │
│  ┌─────────────┐      ┌──────────────────┐                 │
│  │   Restore   │      │  Build llama.cpp │                 │
│  │   Library   │      │  (5-10 minutes)  │                 │
│  └─────────────┘      └────────┬─────────┘                 │
│                                 │                            │
│                                 ▼                            │
│                        ┌──────────────────┐                 │
│                        │  Save to Cache   │                 │
│                        └──────────────────┘                 │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Flutter Build (with libraries)             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Cache Strategy

**Cache Key Format:**
```
llama-{platform}-{hash(llama-version.txt)}
```

**Examples:**
- `llama-android-a1b2c3d4`
- `llama-ios-a1b2c3d4`

**Cache Invalidation:**
When `scripts/llama-version.txt` is updated, the hash changes, invalidating the cache and triggering a rebuild.

## Platform-Specific Details

### Android Build

**Target Architecture:** ARM64-v8a (primary)

**Build Steps:**
1. Check cache for `android/app/src/main/jniLibs`
2. If cache miss:
   - Clone llama.cpp repository
   - Checkout version from `llama-version.txt`
   - Build with Android NDK
   - Output: `libllama.so`
3. Copy library to `android/app/src/main/jniLibs/arm64-v8a/`
4. Verify library exists
5. Proceed with Flutter build

**Requirements:**
- Android NDK 25.1.8937393 (specified in `android/app/build.gradle`)
- CMake
- Git

**Build Time:**
- First build: ~5-7 minutes
- Cached: ~30 seconds

### iOS Build

**Target Architectures:**
- ARM64 (iOS devices)
- x86_64 + ARM64 (iOS Simulator)

**Build Steps:**
1. Check cache for `ios/Frameworks/llama.xcframework`
2. If cache miss:
   - Clone llama.cpp repository
   - Checkout version from `llama-version.txt`
   - Build for iOS devices (ARM64) with Metal support
   - Build for iOS Simulator (x86_64 + ARM64)
   - Create XCFramework
3. Verify framework exists
4. Configure Xcode project (if needed)
5. Proceed with Flutter build

**Requirements:**
- macOS (self-hosted runner)
- Xcode Command Line Tools
- CMake
- Git

**Build Time:**
- First build: ~8-10 minutes
- Cached: ~30 seconds

## MacInCloud Runner Setup

Since both Android and iOS builds run on the same self-hosted MacInCloud runner, the workflow is optimized to:

1. **Sequential Builds**: Android and iOS jobs run sequentially (not parallel)
2. **Separate Caches**: Each platform has its own cache
3. **Shared llama.cpp Clone**: The `build/llama.cpp` directory is reused between builds

### Runner Requirements

**Installed Software:**
- macOS (latest stable)
- Xcode (latest stable)
- Android Studio with NDK 25.1.8937393
- Flutter SDK 3.19.0
- CMake
- Git

**Environment Variables:**
```bash
ANDROID_NDK_HOME=/path/to/android-ndk
# or
ANDROID_NDK=/path/to/android-ndk
```

## Workflow Configuration

### Key Workflow Steps

**Android Job:**
```yaml
- name: Cache llama.cpp Android libraries
  uses: actions/cache@v4
  with:
    path: android/app/src/main/jniLibs
    key: llama-android-${{ hashFiles('scripts/llama-version.txt') }}

- name: Build llama.cpp for Android
  if: steps.cache-llama-android.outputs.cache-hit != 'true'
  run: bash scripts/build-llama-android.sh
```

**iOS Job:**
```yaml
- name: Cache llama.cpp iOS libraries
  uses: actions/cache@v4
  with:
    path: ios/Frameworks/llama.xcframework
    key: llama-ios-${{ hashFiles('scripts/llama-version.txt') }}

- name: Build llama.cpp for iOS
  if: steps.cache-llama-ios.outputs.cache-hit != 'true'
  run: bash scripts/build-llama-ios.sh
```

## Updating llama.cpp Version

### Process

1. **Update version file:**
   ```bash
   # Edit scripts/llama-version.txt
   # Change commit hash to new version (e.g., b4314)
   ```

2. **Commit and push:**
   ```bash
   git add scripts/llama-version.txt
   git commit -m "Update llama.cpp to version b4314"
   git push
   ```

3. **CI/CD automatically:**
   - Detects version change (cache key changes)
   - Rebuilds libraries for both platforms
   - Caches new libraries
   - Builds Flutter app with new libraries

### Version Selection

**Recommended:** Use stable commit hashes from llama.cpp master branch

**Check latest version:**
```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
git log --oneline -10
```

**Test locally before updating CI/CD:**
```bash
# Update llama-version.txt locally
bash scripts/build-llama-android.sh
bash scripts/build-llama-ios.sh
flutter run
```

## Troubleshooting

### Cache Not Working

**Symptom:** Libraries rebuild on every CI/CD run

**Solutions:**
1. Check cache key is correct
2. Verify `llama-version.txt` is committed
3. Check GitHub Actions cache storage limits

### Build Fails in CI/CD

**Android:**
```
Error: ANDROID_NDK_HOME not set
```
**Solution:** Configure NDK path in runner environment

**iOS:**
```
Error: iOS build requires macOS
```
**Solution:** Ensure job runs on macOS runner (self-hosted)

### Library Not Found During Flutter Build

**Symptom:**
```
Error: libllama.so not found
```

**Solutions:**
1. Check cache restore step succeeded
2. Verify build script completed successfully
3. Check library path is correct

## Performance Optimization

### Current Performance

| Scenario | Android | iOS | Total |
|----------|---------|-----|-------|
| First build (no cache) | ~7 min | ~10 min | ~17 min |
| Cached build | ~30 sec | ~30 sec | ~1 min |
| After version update | ~7 min | ~10 min | ~17 min |

### Optimization Tips

1. **Keep llama.cpp version stable** - Only update when necessary
2. **Use cache restore-keys** - Allows partial cache hits
3. **Parallel builds** - If using multiple runners, build Android and iOS in parallel
4. **Incremental builds** - Cache `build/llama.cpp` directory to avoid re-cloning

## Monitoring

### Check Cache Status

In GitHub Actions logs, look for:
```
Cache restored from key: llama-android-a1b2c3d4
```
or
```
Cache not found for input keys: llama-android-a1b2c3d4
```

### Verify Library Sizes

**Expected sizes:**
- Android `libllama.so`: ~15-20 MB
- iOS `llama.xcframework`: ~40-50 MB (includes device + simulator)

## Resources

- **GitHub Actions Cache**: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows
- **llama.cpp Build Docs**: https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md
- **Android NDK**: https://developer.android.com/ndk/guides
- **Xcode Build Settings**: https://developer.apple.com/documentation/xcode

