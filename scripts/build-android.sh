#!/bin/bash

# Build script for Android platform
# Generates and builds CameraGestures library for Android

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-android"

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
ANDROID_ABI="arm64-v8a"
ANDROID_API=21

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
        --abi)
            ANDROID_ABI="$2"
            shift
            ;;
        --api)
            ANDROID_API="$2"
            shift
            ;;
        --all-abis)
            ANDROID_ABI="all"
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --debug          Build debug version"
            echo "  --clean          Clean build directory before building"
            echo "  --generate-only  Only generate build files without building"
            echo "  --abi ABI        Target ABI (arm64-v8a, armeabi-v7a, x86, x86_64)"
            echo "  --api LEVEL      Android API level (default: 21)"
            echo "  --all-abis       Build for all ABIs"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Build for arm64-v8a"
            echo "  $0 --abi armeabi-v7a      # Build for 32-bit ARM"
            echo "  $0 --all-abis             # Build for all ABIs"
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
    print_error "CMake not found. Please install CMake 3.16 or later"
    exit 1
fi

if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$ANDROID_NDK_ROOT" ]; then
    print_error "Android NDK not found. Please set ANDROID_NDK_HOME or ANDROID_NDK_ROOT environment variable"
    echo "  export ANDROID_NDK_HOME=/path/to/android-ndk"
    exit 1
fi

# Use ANDROID_NDK_ROOT if ANDROID_NDK_HOME is not set
NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_NDK_ROOT}"

if [ ! -f "$NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
    print_error "Android NDK toolchain not found at: $NDK_HOME"
    exit 1
fi

# Check MediaPipe (note: may need Android-specific MediaPipe build)
if [ ! -d "$PROJECT_ROOT/third_party/mediapipe" ]; then
    print_warning "MediaPipe not found. You may need to build MediaPipe for Android separately."
fi

# Function to build for a single ABI
build_for_abi() {
    local ABI=$1
    local ABI_BUILD_DIR="$BUILD_DIR/$ABI"
    
    print_info "Building for Android ABI: $ABI (API level: $ANDROID_API)"
    
    # Create build directory
    mkdir -p "$ABI_BUILD_DIR"
    cd "$ABI_BUILD_DIR"
    
    # Generate build files
    cmake "$PROJECT_ROOT" \
        -DCMAKE_TOOLCHAIN_FILE="$NDK_HOME/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="android-$ANDROID_API" \
        -DANDROID_STL=c++_shared \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DUSE_TENSORFLOW=ON \
        -DUSE_SKLEARN=OFF \
        -DANDROID_ARM_NEON=ON
    
    if [ $? -ne 0 ]; then
        print_error "CMake configuration failed for $ABI"
        return 1
    fi
    
    # Build if not generate-only
    if [ "$GENERATE_ONLY" != true ]; then
        cmake --build . --config "$BUILD_TYPE" -- -j$(nproc)
        
        if [ $? -ne 0 ]; then
            print_error "Build failed for $ABI"
            return 1
        fi
        
        print_info "Build complete for $ABI"
        print_info "Libraries located at: $ABI_BUILD_DIR/lib/"
    fi
    
    return 0
}

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Build for specified ABI(s)
if [ "$ANDROID_ABI" = "all" ]; then
    # Build for all common ABIs
    ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
    for ABI in "${ABIS[@]}"; do
        build_for_abi "$ABI" || exit 1
    done
    
    # Create AAR package if all builds successful
    if [ "$GENERATE_ONLY" != true ]; then
        print_info "Creating Android AAR package..."
        
        AAR_DIR="$BUILD_DIR/aar"
        mkdir -p "$AAR_DIR/jni"
        mkdir -p "$AAR_DIR/prefab/modules/cameragestures/libs"
        
        # Copy libraries for each ABI
        for ABI in "${ABIS[@]}"; do
            if [ -d "$BUILD_DIR/$ABI/lib" ]; then
                mkdir -p "$AAR_DIR/jni/$ABI"
                cp "$BUILD_DIR/$ABI/lib/"*.so "$AAR_DIR/jni/$ABI/" 2>/dev/null || true
                
                # Prefab structure
                mkdir -p "$AAR_DIR/prefab/modules/cameragestures/libs/android.$ABI"
                cp "$BUILD_DIR/$ABI/lib/libHandGestureRecognizing.so" \
                   "$AAR_DIR/prefab/modules/cameragestures/libs/android.$ABI/" 2>/dev/null || true
            fi
        done
        
        # Copy headers
        mkdir -p "$AAR_DIR/prefab/modules/cameragestures/include"
        cp -R "$PROJECT_ROOT/include/CameraGestures/"* "$AAR_DIR/prefab/modules/cameragestures/include/"
        
        # Create module.json for Prefab
        cat > "$AAR_DIR/prefab/modules/cameragestures/module.json" << 'EOF'
{
  "library_name": "libHandGestureRecognizing",
  "export_libraries": ["libc++_shared"],
  "android": {
    "export_libraries": ["log", "android"]
  }
}
EOF
        
        # Create prefab.json
        cat > "$AAR_DIR/prefab/prefab.json" << 'EOF'
{
  "name": "cameragestures",
  "schema_version": 1,
  "dependencies": [],
  "version": "1.0.0"
}
EOF
        
        print_info "AAR structure created at: $AAR_DIR"
        print_info "You can package this into an AAR file for Android Studio integration"
    fi
else
    # Build for single ABI
    build_for_abi "$ANDROID_ABI" || exit 1
fi

# Create JNI wrapper template
if [ "$GENERATE_ONLY" != true ]; then
    print_info "Creating JNI wrapper template..."
    
    JNI_DIR="$BUILD_DIR/jni"
    mkdir -p "$JNI_DIR"
    
    cat > "$JNI_DIR/CameraGesturesJNI.cpp" << 'EOF'
#include <jni.h>
#include <android/log.h>
#include "CameraGestures/HandGestureRecognizing/CameraGestureAPI.h"

#define LOG_TAG "CameraGestures"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_cameragestures_CameraGesturesNative_createRecognizer(JNIEnv* env, jobject /* this */) {
    CGHandGestureRecognizerRef recognizer = cg_create_recognizer();
    return reinterpret_cast<jlong>(recognizer);
}

JNIEXPORT void JNICALL
Java_com_cameragestures_CameraGesturesNative_destroyRecognizer(JNIEnv* env, jobject /* this */, jlong handle) {
    CGHandGestureRecognizerRef recognizer = reinterpret_cast<CGHandGestureRecognizerRef>(handle);
    cg_destroy_recognizer(recognizer);
}

JNIEXPORT jint JNICALL
Java_com_cameragestures_CameraGesturesNative_initialize(JNIEnv* env, jobject /* this */, jlong handle, jstring modelPath) {
    CGHandGestureRecognizerRef recognizer = reinterpret_cast<CGHandGestureRecognizerRef>(handle);
    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    
    CGConfig config = {0};
    config.modelPath = path;
    config.cameraIndex = 0;
    config.targetFPS = 30;
    config.minDetectionConfidence = 0.5f;
    config.minTrackingConfidence = 0.5f;
    config.predictionThreshold = 0.7f;
    
    CGErrorCode result = cg_initialize(recognizer, &config);
    
    env->ReleaseStringUTFChars(modelPath, path);
    return static_cast<jint>(result);
}

} // extern "C"
EOF
    
    print_info "JNI wrapper template created at: $JNI_DIR/CameraGesturesJNI.cpp"
fi

print_info "Android build setup complete!"
