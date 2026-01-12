#!/bin/bash
set -e

echo "========================================="
echo "Building llama.cpp for Android"
echo "========================================="

# Configuration
# Pick the first non-empty, non-comment line from scripts/llama-version.txt
LLAMA_VERSION=$(grep -v '^[[:space:]]*#' scripts/llama-version.txt | grep -v '^[[:space:]]*$' | head -n 1)
if [ -z "$LLAMA_VERSION" ]; then
    echo "Error: Could not determine llama.cpp version from scripts/llama-version.txt"
    exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LLAMA_DIR="$PROJECT_ROOT/build/llama.cpp"
OUTPUT_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

# Local persistent cache (useful for CI self-hosted runners)
CACHE_ROOT="${LLAMA_CACHE_ROOT:-$HOME/.cache/cruises-mobile/llama}"
CACHED_LIB="$CACHE_ROOT/android/$LLAMA_VERSION/arm64-v8a/libllama.so"

echo "llama.cpp version: $LLAMA_VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Output directory: $OUTPUT_DIR"

# Fast path: reuse locally cached artifact if present
if [ -f "$CACHED_LIB" ]; then
    echo "Using cached libllama.so: $CACHED_LIB"
    mkdir -p "$OUTPUT_DIR/arm64-v8a"
    cp "$CACHED_LIB" "$OUTPUT_DIR/arm64-v8a/libllama.so"
    echo "✅ Reused cached Android llama.cpp library"
    exit 0
fi

resolve_ndk_path() {
    # 1) Explicit env vars (preferred)
    if [ -n "$ANDROID_NDK_HOME" ] && [ -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
        echo "$ANDROID_NDK_HOME"
        return 0
    fi
    if [ -n "$ANDROID_NDK" ] && [ -f "$ANDROID_NDK/build/cmake/android.toolchain.cmake" ]; then
        echo "$ANDROID_NDK"
        return 0
    fi

    # 2) Try to infer from Android SDK root
    # Common locations on self-hosted macOS runners include:
    #   - $ANDROID_SDK_ROOT
    #   - $ANDROID_HOME
    #   - $HOME/Library/Android/sdk
    #   - $HOME/Android/Sdk
    local sdk_root
    for sdk_root in "$ANDROID_SDK_ROOT" "$ANDROID_HOME" "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" \
        "/usr/local/share/android-sdk" "/opt/android-sdk"; do
        if [ -n "$sdk_root" ] && [ -d "$sdk_root" ]; then
            # Legacy NDK location
            if [ -f "$sdk_root/ndk-bundle/build/cmake/android.toolchain.cmake" ]; then
                echo "$sdk_root/ndk-bundle"
                return 0
            fi

            # Modern NDK location: $SDK/ndk/<version>
            if [ -d "$sdk_root/ndk" ]; then
                local newest
                newest=$(ls -1dt "$sdk_root/ndk/"* 2>/dev/null | head -n 1 || true)
                if [ -n "$newest" ] && [ -f "$newest/build/cmake/android.toolchain.cmake" ]; then
                    echo "$newest"
                    return 0
                fi
            fi
        fi
    done

    return 1
}

# Resolve Android NDK path (env var or auto-detected)
NDK_PATH="$(resolve_ndk_path || true)"
if [ -z "$NDK_PATH" ]; then
    echo "Error: Android NDK not found."
    echo "Tried ANDROID_NDK_HOME/ANDROID_NDK, then SDK roots: ANDROID_SDK_ROOT, ANDROID_HOME, ~/Library/Android/sdk, ~/Android/Sdk."
    echo "Please install Android NDK and/or set ANDROID_NDK_HOME to your NDK path."
    exit 1
fi

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
git fetch --tags origin
if ! git rev-parse --verify --quiet "$LLAMA_VERSION^{commit}" >/dev/null; then
    echo "Error: llama.cpp ref '$LLAMA_VERSION' was not found after fetch."
    echo "Update scripts/llama-version.txt to a valid tag/commit hash from ggml-org/llama.cpp."
    exit 1
fi
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
    -DLLAMA_CURL=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DLLAMA_BUILD_COMMON=OFF \
    -DCMAKE_BUILD_TYPE=Release

CPU_COUNT=$(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu)
cmake --build . --config Release -j$CPU_COUNT

# Copy library to Flutter project
echo "Copying libllama.so to Flutter project..."
mkdir -p "$OUTPUT_DIR/arm64-v8a"

# llama.cpp output path varies by version/config (commonly src/ or bin/). Try known locations first.
SO_PATH=""
for candidate in "src/libllama.so" "bin/libllama.so" "libllama.so"; do
    if [ -f "$candidate" ]; then
        SO_PATH="$candidate"
        break
    fi
done

if [ -z "$SO_PATH" ]; then
    echo "❌ Error: libllama.so not found (checked: src/, bin/, root)."
    echo "Listing possible libllama.so locations (up to depth 4):"
    find . -maxdepth 4 -name libllama.so -print || true
    exit 70
fi

echo "Found libllama.so at: $BUILD_DIR/$SO_PATH"
cp "$SO_PATH" "$OUTPUT_DIR/arm64-v8a/libllama.so"

# Save to local cache for subsequent runs
echo "Saving libllama.so to local cache..."
mkdir -p "$(dirname "$CACHED_LIB")"
cp "$SO_PATH" "$CACHED_LIB"

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

