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
CACHE_DIR="$CACHE_ROOT/android/$LLAMA_VERSION/arm64-v8a"

echo "llama.cpp version: $LLAMA_VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Output directory: $OUTPUT_DIR"

# Fast path: reuse locally cached artifacts if present
# Check for libllama.so and libggml.so (the two essential libraries)
if [ -f "$CACHE_DIR/libllama.so" ] && [ -f "$CACHE_DIR/libggml.so" ]; then
    echo "Using cached libraries from: $CACHE_DIR/"
    mkdir -p "$OUTPUT_DIR/arm64-v8a"
    # Copy all cached .so files
    for cached_so in "$CACHE_DIR"/*.so; do
        if [ -f "$cached_so" ]; then
            cp "$cached_so" "$OUTPUT_DIR/arm64-v8a/"
        fi
    done
    echo "✅ Reused cached Android llama.cpp libraries:"
    ls -lh "$OUTPUT_DIR/arm64-v8a/"*.so 2>/dev/null || true
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
    -DLLAMA_BUILD_COMMON=ON \
    -DGGML_NATIVE=OFF \
    -DCMAKE_BUILD_TYPE=Release

CPU_COUNT=$(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu)
cmake --build . --config Release -j$CPU_COUNT

# List all generated .so files for debugging
echo ""
echo "All generated .so files:"
find . -name "*.so" -type f 2>/dev/null | head -50

# Copy libraries to Flutter project
echo ""
echo "Copying libraries to Flutter project..."
mkdir -p "$OUTPUT_DIR/arm64-v8a"

# Helper function to find a library
find_lib() {
    local libname="$1"
    for candidate in "bin/$libname" "src/$libname" "$libname" "tools/mtmd/$libname" "common/$libname" \
                     "ggml/src/$libname" "ggml/src/ggml/$libname"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    # Fallback: search recursively
    find . -maxdepth 5 -name "$libname" -print -quit 2>/dev/null || true
}

# Copy all ggml libraries (dependencies of libllama.so)
# With BUILD_SHARED_LIBS=ON, llama.cpp creates separate .so files for each component
echo "Copying ggml libraries..."
for ggml_lib in libggml.so libggml-base.so libggml-cpu.so; do
    GGML_PATH="$(find_lib $ggml_lib)"
    if [ -n "$GGML_PATH" ] && [ -f "$GGML_PATH" ]; then
        echo "  Found $ggml_lib at: $GGML_PATH"
        cp "$GGML_PATH" "$OUTPUT_DIR/arm64-v8a/$ggml_lib"
    fi
done

# Find and copy libllama.so
LLAMA_SO_PATH="$(find_lib libllama.so)"
if [ -z "$LLAMA_SO_PATH" ]; then
    echo "❌ Error: libllama.so not found."
    echo "Listing possible libllama.so locations (up to depth 5):"
    find . -maxdepth 5 -name libllama.so -print || true
    exit 70
fi
echo "Found libllama.so at: $BUILD_DIR/$LLAMA_SO_PATH"
cp "$LLAMA_SO_PATH" "$OUTPUT_DIR/arm64-v8a/libllama.so"

# Find and copy libmtmd.so (multimodal support for llama_cpp_dart 0.2.x)
MTMD_SO_PATH="$(find_lib libmtmd.so)"
if [ -z "$MTMD_SO_PATH" ]; then
    echo "⚠️  Warning: libmtmd.so not found. Multimodal features may not work."
    echo "Listing possible libmtmd.so locations (up to depth 5):"
    find . -maxdepth 5 -name libmtmd.so -print || true
    # Create empty placeholder to avoid runtime errors
    touch "$OUTPUT_DIR/arm64-v8a/libmtmd.so.missing"
else
    echo "Found libmtmd.so at: $BUILD_DIR/$MTMD_SO_PATH"
    cp "$MTMD_SO_PATH" "$OUTPUT_DIR/arm64-v8a/libmtmd.so"
fi

# Find and copy libcommon.so if exists
COMMON_SO_PATH="$(find_lib libcommon.so)"
if [ -n "$COMMON_SO_PATH" ] && [ -f "$COMMON_SO_PATH" ]; then
    echo "Found libcommon.so at: $BUILD_DIR/$COMMON_SO_PATH"
    cp "$COMMON_SO_PATH" "$OUTPUT_DIR/arm64-v8a/libcommon.so"
fi

# Save to local cache for subsequent runs
echo "Saving libraries to local cache..."
CACHE_DIR="$CACHE_ROOT/android/$LLAMA_VERSION/arm64-v8a"
mkdir -p "$CACHE_DIR"
# Copy all .so files from output to cache
for so_file in "$OUTPUT_DIR/arm64-v8a"/*.so; do
    if [ -f "$so_file" ]; then
        cp "$so_file" "$CACHE_DIR/"
    fi
done

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

