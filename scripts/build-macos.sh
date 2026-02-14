#!/bin/bash

# Build script for macOS platform
# Generates Xcode project and builds CameraGestures library

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-macos"

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
BUILD_TESTS=OFF

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
        --with-tests)
            BUILD_TESTS=ON
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --debug          Build debug version"
            echo "  --clean          Clean build directory before building"
            echo "  --generate-only  Only generate Xcode project without building"
            echo "  --with-tests     Build unit tests"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Build release version"
            echo "  $0 --debug            # Build debug version"
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

# Check MediaPipe
if [ ! -d "$PROJECT_ROOT/third_party/mediapipe" ]; then
    print_warning "MediaPipe not found. Running setup script..."
    "$PROJECT_ROOT/scripts/setup_mediapipe_macos.sh"
fi

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Generate Xcode project
print_info "Generating Xcode project..."

cmake .. \
    -G "Xcode" \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTS=$BUILD_TESTS \
    -DBUILD_EXAMPLES=ON \
    -DUSE_TENSORFLOW=ON \
    -DUSE_SKLEARN=OFF

if [ $? -ne 0 ]; then
    print_error "CMake configuration failed"
    exit 1
fi

print_info "Xcode project generated at: $BUILD_DIR/CameraGestures.xcodeproj"

# Build if not generate-only
if [ "$GENERATE_ONLY" != true ]; then
    print_info "Building CameraGestures ($BUILD_TYPE)..."
    
    xcodebuild \
        -project CameraGestures.xcodeproj \
        -configuration $BUILD_TYPE \
        -target ALL_BUILD \
        build
    
    if [ $? -ne 0 ]; then
        print_error "Build failed"
        exit 1
    fi
    
    print_info "Build complete!"
    print_info "Libraries located at: $BUILD_DIR/lib/"
    print_info "Headers located at: $PROJECT_ROOT/include/"
    
    # Run tests if built
    if [ "$BUILD_TESTS" = "ON" ]; then
        print_info "Running tests..."
        ctest --output-on-failure -C $BUILD_TYPE
    fi
fi

# Create a simple wrapper script for the ModelTraining app
if [ -d "$PROJECT_ROOT/ModelTraining" ]; then
    print_info "Creating ModelTraining app build script..."
    cat > "$BUILD_DIR/build-training-app.sh" << 'EOF'
#!/bin/bash
# Build the Swift ModelTraining app
cd "$(dirname "$0")/../ModelTraining"
swift build -c release
echo "ModelTraining app built successfully"
EOF
    chmod +x "$BUILD_DIR/build-training-app.sh"
fi

print_info "macOS build setup complete!"
