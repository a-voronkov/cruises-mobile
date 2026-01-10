#!/bin/bash
set -e

echo "========================================="
echo "Building llama.cpp for Android"
echo "========================================="

# Configuration
LLAMA_VERSION=$(head -n 6 scripts/llama-version.txt | tail -n 1)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LLAMA_DIR="$PROJECT_ROOT/build/llama.cpp"
OUTPUT_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

echo "llama.cpp version: $LLAMA_VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Output directory: $OUTPUT_DIR"

# Check if Android NDK is available
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$ANDROID_NDK" ]; then
    echo "Error: ANDROID_NDK_HOME or ANDROID_NDK environment variable not set"
    echo "Please set it to your Android NDK installation path"
    exit 1
fi

NDK_PATH="${ANDROID_NDK_HOME:-$ANDROID_NDK}"
echo "Using Android NDK: $NDK_PATH"

# Clone llama.cpp if not exists
if [ ! -d "$LLAMA_DIR" ]; then
    echo "Cloning llama.cpp repository..."
    mkdir -p "$(dirname "$LLAMA_DIR")"
    git clone https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
fi

cd "$LLAMA_DIR"

# Checkout specific version
echo "Checking out version: $LLAMA_VERSION"
git fetch origin
git checkout "$LLAMA_VERSION"

# Build for ARM64 (primary architecture for modern Android devices)
echo ""
echo "Building for arm64-v8a..."
BUILD_DIR="build-android-arm64-v8a"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release -j$(nproc)

# Copy library to Flutter project
echo "Copying libllama.so to Flutter project..."
mkdir -p "$OUTPUT_DIR/arm64-v8a"
cp libllama.so "$OUTPUT_DIR/arm64-v8a/"

cd "$LLAMA_DIR"

# Optional: Build for ARMv7 (older devices)
# Uncomment if you need to support older Android devices
# echo ""
# echo "Building for armeabi-v7a..."
# BUILD_DIR="build-android-armeabi-v7a"
# rm -rf "$BUILD_DIR"
# mkdir -p "$BUILD_DIR"
# cd "$BUILD_DIR"
#
# cmake .. \
#     -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
#     -DANDROID_ABI=armeabi-v7a \
#     -DANDROID_PLATFORM=android-24 \
#     -DBUILD_SHARED_LIBS=ON \
#     -DLLAMA_BUILD_TESTS=OFF \
#     -DLLAMA_BUILD_EXAMPLES=OFF \
#     -DLLAMA_BUILD_SERVER=OFF \
#     -DCMAKE_BUILD_TYPE=Release
#
# cmake --build . --config Release -j$(nproc)
#
# mkdir -p "$OUTPUT_DIR/armeabi-v7a"
# cp libllama.so "$OUTPUT_DIR/armeabi-v7a/"

echo ""
echo "========================================="
echo "✅ Android build complete!"
echo "========================================="
echo "Libraries installed to:"
ls -lh "$OUTPUT_DIR"/*/*.so

