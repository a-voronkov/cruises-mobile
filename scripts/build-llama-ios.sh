#!/bin/bash
set -e

echo "========================================="
echo "Building llama.cpp for iOS"
echo "========================================="

# Configuration
LLAMA_VERSION=$(head -n 6 scripts/llama-version.txt | tail -n 1)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LLAMA_DIR="$PROJECT_ROOT/build/llama.cpp"
OUTPUT_DIR="$PROJECT_ROOT/ios/Frameworks"

echo "llama.cpp version: $LLAMA_VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Output directory: $OUTPUT_DIR"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: iOS build requires macOS"
    exit 1
fi

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

# Build for iOS devices (ARM64)
echo ""
echo "Building for iOS devices (arm64)..."
BUILD_DIR_IOS="build-ios-arm64"
rm -rf "$BUILD_DIR_IOS"
mkdir -p "$BUILD_DIR_IOS"
cd "$BUILD_DIR_IOS"

cmake .. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_METAL=ON \
    -DCMAKE_C_FLAGS="-fembed-bitcode" \
    -DCMAKE_CXX_FLAGS="-fembed-bitcode"

cmake --build . --config Release -j$(sysctl -n hw.ncpu)

cd "$LLAMA_DIR"

# Build for iOS Simulator (x86_64 and arm64)
echo ""
echo "Building for iOS Simulator (x86_64 + arm64)..."
BUILD_DIR_SIM="build-ios-simulator"
rm -rf "$BUILD_DIR_SIM"
mkdir -p "$BUILD_DIR_SIM"
cd "$BUILD_DIR_SIM"

cmake .. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_METAL=ON

cmake --build . --config Release -j$(sysctl -n hw.ncpu)

cd "$LLAMA_DIR"

# Create XCFramework
echo ""
echo "Creating XCFramework..."
mkdir -p "$OUTPUT_DIR"

xcodebuild -create-xcframework \
    -library "$BUILD_DIR_IOS/libllama.a" \
    -library "$BUILD_DIR_SIM/libllama.a" \
    -output "$OUTPUT_DIR/llama.xcframework"

# Also copy Metal shader library if it exists
if [ -f "$BUILD_DIR_IOS/bin/ggml-metal.metal" ]; then
    echo "Copying Metal shaders..."
    mkdir -p "$OUTPUT_DIR/MetalShaders"
    cp "$BUILD_DIR_IOS/bin/ggml-metal.metal" "$OUTPUT_DIR/MetalShaders/"
fi

echo ""
echo "========================================="
echo "✅ iOS build complete!"
echo "========================================="
echo "XCFramework created at:"
ls -lh "$OUTPUT_DIR/llama.xcframework"

echo ""
echo "⚠️  IMPORTANT: Add llama.xcframework to your Xcode project:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Drag llama.xcframework to 'Frameworks, Libraries, and Embedded Content'"
echo "3. Set 'Embed & Sign' for the framework"

