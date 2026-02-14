#!/bin/bash

# Build script for iOS platform
# Generates Xcode project and builds CameraGestures framework for iOS

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-ios"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Parse arguments
BUILD_TYPE="Release"
CLEAN_BUILD=false
GENERATE_ONLY=false
PLATFORM="OS64"  # Default to 64-bit iOS
BUILD_SIMULATOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="Debug"
            ;;
        --clean)
            CLEAN_BUILD=true
            ;;
        --generate-only)
            GENERATE_ONLY=true
            ;;
        --simulator)
            BUILD_SIMULATOR=true
            PLATFORM="SIMULATOR64"
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --debug          Build debug version"
            echo "  --clean          Clean build directory before building"
            echo "  --generate-only  Only generate Xcode project without building"
            echo "  --simulator      Build for iOS Simulator instead of device"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Build for iOS device"
            echo "  $0 --simulator        # Build for iOS Simulator"
            echo "  $0 --generate-only    # Only generate Xcode project"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v cmake &> /dev/null; then
    print_error "CMake not found. Please install CMake 3.16 or later:"
    echo "  brew install cmake"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Check for iOS toolchain
if [ ! -f "$PROJECT_ROOT/cmake/ios.toolchain.cmake" ]; then
    print_info "Downloading iOS CMake toolchain..."
    mkdir -p "$PROJECT_ROOT/cmake"
    curl -L -o "$PROJECT_ROOT/cmake/ios.toolchain.cmake" \
        https://raw.githubusercontent.com/leetal/ios-cmake/master/ios.toolchain.cmake
fi

# Check MediaPipe
#if [ ! -d "$PROJECT_ROOT/third_party/mediapipe" ]; then
    #print_warning "MediaPipe not found. Running setup script..."
    #"$PROJECT_ROOT/scripts/setup_mediapipe_macos.sh"
#fi

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Generate Xcode project
print_info "Generating iOS Xcode project (Platform: $PLATFORM)..."

cmake .. \
    -G "Xcode" \
    -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/ios.toolchain.cmake" \
    -DPLATFORM=$PLATFORM \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DUSE_TENSORFLOW=ON \
    -DUSE_SKLEARN=OFF \
    -DENABLE_BITCODE=ON \
    -DENABLE_ARC=ON \
    -DENABLE_VISIBILITY=ON

if [ $? -ne 0 ]; then
    print_error "CMake configuration failed"
    exit 1
fi

print_info "Xcode project generated at: $BUILD_DIR/CameraGestures.xcodeproj"

# Build if not generate-only
if [ "$GENERATE_ONLY" != true ]; then
    print_info "Building CameraGestures for iOS ($BUILD_TYPE)..."

    # Determine SDK
    if [ "$BUILD_SIMULATOR" = true ]; then
        SDK="iphonesimulator"
    else
        SDK="iphoneos"
    fi

    xcodebuild \
        -project CameraGestures.xcodeproj \
        -configuration $BUILD_TYPE \
        -sdk $SDK \
        -target ALL_BUILD \
        build

    if [ $? -ne 0 ]; then
        print_error "Build failed"
        exit 1
    fi

    print_info "Build complete!"
    print_info "Libraries located at: $BUILD_DIR/lib/"

    # Create fat library combining architectures if needed
    if [ "$BUILD_SIMULATOR" != true ]; then
        print_info "Creating universal framework..."

        # Create framework directory structure
        FRAMEWORK_DIR="$BUILD_DIR/CameraGestures.framework"
        mkdir -p "$FRAMEWORK_DIR/Headers"

        # Copy headers
        cp -R "$PROJECT_ROOT/include/CameraGestures/"* "$FRAMEWORK_DIR/Headers/"

        # Combine libraries
        if [ -f "$BUILD_DIR/lib/libHandGestureRecognizing.a" ]; then
            cp "$BUILD_DIR/lib/libHandGestureRecognizing.a" "$FRAMEWORK_DIR/CameraGestures"

            # Create Info.plist
            cat > "$FRAMEWORK_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>CameraGestures</string>
    <key>CFBundleIdentifier</key>
    <string>com.cameragebstures.framework</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CameraGestures</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>11.0</string>
</dict>
</plist>
EOF

            print_info "Framework created at: $FRAMEWORK_DIR"
        fi
    fi
fi

# Create module map for Swift interop
print_info "Creating module map for Swift..."
MODULE_DIR="$BUILD_DIR/CameraGestures.framework/Modules"
mkdir -p "$MODULE_DIR"
cat > "$MODULE_DIR/module.modulemap" << 'EOF'
framework module CameraGestures {
    umbrella header "CameraGestureAPI.h"

    export *
    module * { export * }

    link "c++"
    link "opencv2"
    link "mediapipe"
}
EOF

print_info "iOS build setup complete!"
