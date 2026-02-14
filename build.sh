#!/bin/bash

# Main build coordinator script for CameraGestures project
# Calls platform-specific build scripts

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_header() { echo -e "\n${BLUE}==== $1 ====${NC}\n"; }

# Show usage
show_usage() {
    echo "CameraGestures Build System"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "COMMANDS:"
    echo "  setup       Set up MediaPipe and dependencies"
    echo "  macos       Build for macOS"
    echo "  ios         Build for iOS"  
    echo "  android     Build for Android"
    echo "  all         Build for all platforms"
    echo "  clean       Clean all build directories"
    echo "  help        Show this help message"
    echo ""
    echo "OPTIONS:"
    echo "  Options are passed to platform-specific scripts."
    echo "  Use '$0 [COMMAND] --help' for platform-specific options."
    echo ""
    echo "Examples:"
    echo "  $0 setup                  # Set up MediaPipe"
    echo "  $0 macos                  # Build for macOS"
    echo "  $0 ios --simulator        # Build for iOS Simulator"
    echo "  $0 android --all-abis     # Build for all Android ABIs"
    echo "  $0 all                    # Build for all platforms"
    echo "  $0 clean                  # Clean all builds"
}

# Make all scripts executable
make_scripts_executable() {
    chmod +x "$PROJECT_ROOT/scripts/"*.sh 2>/dev/null || true
}

# Setup MediaPipe
setup_mediapipe() {
    print_header "Setting up MediaPipe"
    
    if [ -f "$PROJECT_ROOT/scripts/setup_mediapipe_macos.sh" ]; then
        "$PROJECT_ROOT/scripts/setup_mediapipe_macos.sh"
    else
        print_error "MediaPipe setup script not found"
        exit 1
    fi
}

# Build for macOS
build_macos() {
    print_header "Building for macOS"
    
    if [ -f "$PROJECT_ROOT/scripts/build-macos.sh" ]; then
        "$PROJECT_ROOT/scripts/build-macos.sh" "$@"
    else
        print_error "macOS build script not found"
        exit 1
    fi
}

# Build for iOS
build_ios() {
    print_header "Building for iOS"
    
    if [ -f "$PROJECT_ROOT/scripts/build-ios.sh" ]; then
        "$PROJECT_ROOT/scripts/build-ios.sh" "$@"
    else
        print_error "iOS build script not found"
        exit 1
    fi
}

# Build for Android
build_android() {
    print_header "Building for Android"
    
    if [ -f "$PROJECT_ROOT/scripts/build-android.sh" ]; then
        "$PROJECT_ROOT/scripts/build-android.sh" "$@"
    else
        print_error "Android build script not found"
        exit 1
    fi
}

# Clean all build directories
clean_all() {
    print_header "Cleaning all build directories"
    
    print_info "Removing build directories..."
    rm -rf "$PROJECT_ROOT/build"
    rm -rf "$PROJECT_ROOT/build-macos"
    rm -rf "$PROJECT_ROOT/build-ios"
    rm -rf "$PROJECT_ROOT/build-android"
    
    print_info "Clean complete!"
}

# Build for all platforms
build_all() {
    print_header "Building for all platforms"
    
    # Build in order: macOS, iOS, Android
    build_macos "$@"
    build_ios "$@"
    
    if [ -n "$ANDROID_NDK_HOME" ] || [ -n "$ANDROID_NDK_ROOT" ]; then
        build_android "$@"
    else
        print_warning "Skipping Android build - ANDROID_NDK_HOME not set"
    fi
    
    print_header "All builds complete!"
}

# Main logic
main() {
    make_scripts_executable
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    # Get command
    COMMAND=$1
    shift
    
    # Execute command
    case $COMMAND in
        setup)
            setup_mediapipe
            ;;
        macos)
            build_macos "$@"
            ;;
        ios)
            build_ios "$@"
            ;;
        android)
            build_android "$@"
            ;;
        all)
            build_all "$@"
            ;;
        clean)
            clean_all
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
