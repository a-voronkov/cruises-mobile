# llama.cpp Setup Guide for Flutter

This guide explains how to build and integrate llama.cpp library for the Cruises Mobile app.

## Overview

The app uses `llama_cpp_dart` package which requires a compiled llama.cpp shared library for each platform.

## Prerequisites

- **Windows**: Visual Studio 2019+ with C++ tools, CMake
- **macOS**: Xcode Command Line Tools, CMake
- **Linux**: GCC/Clang, CMake
- **Android**: Android NDK
- **iOS**: Xcode

## Building llama.cpp

### 1. Clone llama.cpp Repository

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
```

### 2. Build for Desktop Platforms

#### Windows (CPU)

```powershell
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release
```

Output: `build/bin/Release/llama.dll`

#### macOS (CPU + Metal)

```bash
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=ON
cmake --build . --config Release
```

Output: `build/libllama.dylib`

#### Linux (CPU)

```bash
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release
```

Output: `build/libllama.so`

### 3. Build for Mobile Platforms

#### Android

Create a build script `build-android.sh`:

```bash
#!/bin/bash

# Set NDK path
export ANDROID_NDK=/path/to/android-ndk

# Build for each architecture
for ARCH in arm64-v8a armeabi-v7a x86_64 x86; do
    mkdir -p build-android-$ARCH
    cd build-android-$ARCH
    
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI=$ARCH \
        -DANDROID_PLATFORM=android-24 \
        -DBUILD_SHARED_LIBS=ON \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_EXAMPLES=OFF
    
    cmake --build . --config Release
    cd ..
done
```

Output: `build-android-{arch}/libllama.so`

Place in: `android/app/src/main/jniLibs/{arch}/libllama.so`

#### iOS

```bash
# Build for iOS devices (arm64)
mkdir build-ios
cd build-ios
cmake .. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_METAL=ON
cmake --build . --config Release

# Build for iOS simulator (x86_64, arm64)
mkdir build-ios-simulator
cd build-ios-simulator
cmake .. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release
```

Create XCFramework:

```bash
xcodebuild -create-xcframework \
    -library build-ios/libllama.dylib \
    -library build-ios-simulator/libllama.dylib \
    -output llama.xcframework
```

Place in: `ios/Frameworks/llama.xcframework`

## Integration with Flutter

### Option 1: Automatic (Recommended for Development)

The `llama_cpp_dart` package will try to find the library automatically. Place the compiled library in:

- **Windows**: `C:\Windows\System32\llama.dll` or project root
- **macOS**: `/usr/local/lib/libllama.dylib` or project root
- **Linux**: `/usr/lib/libllama.so` or project root

### Option 2: Manual Path (Production)

Set the library path in code:

```dart
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

void main() {
  // Set library path before using
  Llama.libraryPath = '/path/to/libllama.dylib';
  
  // ... rest of your code
}
```

### Option 3: Bundle with App

#### Android

1. Place `libllama.so` in `android/app/src/main/jniLibs/{arch}/`
2. The library will be automatically included in the APK

#### iOS

1. Add `llama.xcframework` to Xcode project
2. Embed & Sign the framework

## Download Pre-built Libraries (Alternative)

If you don't want to build from source, you can download pre-built libraries:

### Windows/macOS/Linux

Check llama.cpp releases: https://github.com/ggml-org/llama.cpp/releases

### Android/iOS

Some community members provide pre-built libraries. Search for:
- "llama.cpp android prebuilt"
- "llama.cpp ios xcframework"

**⚠️ Warning**: Only use pre-built libraries from trusted sources.

## Verification

Test if the library is working:

```dart
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

void testLibrary() {
  try {
    Llama.libraryPath = '/path/to/library';
    print('Library loaded successfully!');
  } catch (e) {
    print('Failed to load library: $e');
  }
}
```

## Troubleshooting

### Library not found

- Check file path and permissions
- Verify architecture matches (x64, arm64, etc.)
- On macOS, run: `otool -L libllama.dylib` to check dependencies

### Undefined symbols

- Rebuild with correct flags
- Check CMake configuration

### Android: UnsatisfiedLinkError

- Verify library is in correct `jniLibs/{arch}/` folder
- Check ABI matches device architecture
- Rebuild with correct NDK version

### iOS: dyld error

- Ensure framework is embedded and signed
- Check deployment target matches

## Performance Optimization

### Enable GPU Acceleration

#### Metal (macOS/iOS)

```bash
cmake .. -DLLAMA_METAL=ON
```

#### CUDA (NVIDIA GPU)

```bash
cmake .. -DLLAMA_CUBLAS=ON
```

#### ROCm (AMD GPU)

```bash
cmake .. -DLLAMA_HIPBLAS=ON
```

### Enable Optimizations

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DLLAMA_NATIVE=ON
```

## Next Steps

1. Build llama.cpp library for your platform
2. Place library in correct location
3. Download LFM2.5 model (see `docs/LFM2.5_INTEGRATION.md`)
4. Run the app and test inference

## Resources

- llama.cpp GitHub: https://github.com/ggml-org/llama.cpp
- llama_cpp_dart package: https://pub.dev/packages/llama_cpp_dart
- Build documentation: https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md

