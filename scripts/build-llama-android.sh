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

# Build flags version - increment when cmake flags change to invalidate cache
BUILD_FLAGS_VERSION="v4-static-ggml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LLAMA_DIR="$PROJECT_ROOT/build/llama.cpp"
OUTPUT_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

# Local persistent cache (useful for CI self-hosted runners)
# Cache key includes llama version AND build flags version
CACHE_ROOT="${LLAMA_CACHE_ROOT:-$HOME/.cache/cruises-mobile/llama}"
CACHE_DIR="$CACHE_ROOT/android/$LLAMA_VERSION-$BUILD_FLAGS_VERSION/arm64-v8a"

echo "llama.cpp version: $LLAMA_VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Output directory: $OUTPUT_DIR"

# Fast path: reuse locally cached artifacts if present
# With GGML_STATIC=ON, only libllama.so is essential (ggml is statically linked)
if [ -f "$CACHE_DIR/libllama.so" ]; then
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

# Setup OpenCL for GPU acceleration on Android
OPENCL_DIR="$PROJECT_ROOT/build/opencl"
OPENCL_HEADERS_DIR="$OPENCL_DIR/OpenCL-Headers"
OPENCL_LIBS_DIR="$OPENCL_DIR/libs"

setup_opencl() {
    echo ""
    echo "Setting up OpenCL for Android..."
    mkdir -p "$OPENCL_DIR"

    # Download OpenCL headers if not present
    if [ ! -d "$OPENCL_HEADERS_DIR" ]; then
        echo "Downloading OpenCL headers..."
        git clone --depth 1 https://github.com/KhronosGroup/OpenCL-Headers.git "$OPENCL_HEADERS_DIR"
    fi

    # Download OpenCL stub library from llama_cpp_dart if not present
    if [ ! -f "$OPENCL_LIBS_DIR/arm64-v8a/libOpenCL.so" ]; then
        echo "Downloading OpenCL stub library..."
        mkdir -p "$OPENCL_LIBS_DIR/arm64-v8a"
        curl -L -o "$OPENCL_LIBS_DIR/arm64-v8a/libOpenCL.so" \
            "https://github.com/netdur/llama_cpp_dart/raw/main/src/opencl-libs/android/arm64-v8a/libOpenCL.so"
    fi

    echo "OpenCL setup complete."
}

setup_opencl

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

# Build with GGML_STATIC=ON to statically link ggml into libllama.so
# This avoids the "dlopen failed: library libggml-cpu.so not found" error on Android
# because all ggml code is embedded directly into libllama.so
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_STATIC=ON \
    -DLLAMA_CURL=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DLLAMA_BUILD_COMMON=ON \
    -DGGML_NATIVE=OFF \
    -DGGML_OPENMP=OFF \
    -DGGML_LLAMAFILE=OFF \
    -DGGML_OPENCL=ON \
    -DGGML_OPENCL_EMBED_KERNELS=ON \
    -DGGML_OPENCL_USE_ADRENO_KERNELS=ON \
    -DOpenCL_INCLUDE_DIR="$OPENCL_HEADERS_DIR" \
    -DOpenCL_LIBRARY="$OPENCL_LIBS_DIR/arm64-v8a/libOpenCL.so" \
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

# With GGML_STATIC=ON, ggml is statically linked into libllama.so
# No need to copy separate ggml libraries (libggml.so, libggml-cpu.so, etc.)
# This avoids the "dlopen failed: library libggml-cpu.so not found" error on Android
echo "Note: ggml is statically linked into libllama.so (GGML_STATIC=ON)"

# Copy OpenCL stub library (required for GPU acceleration on Android)
echo "Copying OpenCL library..."
if [ -f "$OPENCL_LIBS_DIR/arm64-v8a/libOpenCL.so" ]; then
    cp "$OPENCL_LIBS_DIR/arm64-v8a/libOpenCL.so" "$OUTPUT_DIR/arm64-v8a/libOpenCL.so"
    echo "  Copied libOpenCL.so"
fi

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
CACHE_DIR="$CACHE_ROOT/android/$LLAMA_VERSION-$BUILD_FLAGS_VERSION/arm64-v8a"
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

