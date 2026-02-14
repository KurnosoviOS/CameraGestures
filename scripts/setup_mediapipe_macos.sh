#!/bin/bash

# MediaPipe setup script for macOS
# This script downloads and builds MediaPipe for use with CameraGestures

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
THIRD_PARTY_DIR="$PROJECT_ROOT/third_party"
MEDIAPIPE_DIR="$THIRD_PARTY_DIR/mediapipe"

echo "Setting up MediaPipe for CameraGestures..."

# Create third party directory
mkdir -p "$THIRD_PARTY_DIR"
cd "$THIRD_PARTY_DIR"

# Check if MediaPipe already exists
if [ -d "$MEDIAPIPE_DIR" ]; then
    echo "MediaPipe directory already exists. Updating..."
    cd "$MEDIAPIPE_DIR"
    git pull
else
    echo "Cloning MediaPipe repository..."
    git clone https://github.com/google/mediapipe.git
    cd "$MEDIAPIPE_DIR"
fi

# Install Bazel if not already installed
if ! command -v bazel &> /dev/null; then
    echo "Installing Bazel..."
    brew install bazel@7
fi

# Install other dependencies
echo "Installing dependencies..."
brew install opencv@4 protobuf eigen

# Build MediaPipe hands tracking library
echo "Building MediaPipe hands tracking..."

# Create build script
cat > build_hands.sh << 'EOF'
#!/bin/bash

# Build hand landmark tracking CPU library
bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 \
    //mediapipe/modules/hand_landmark:hand_landmark_tracking_cpu \
    //mediapipe/framework:calculator_framework \
    //mediapipe/calculators/core:pass_through_calculator \
    //mediapipe/calculators/image:image_properties_calculator

# Create lib directory
mkdir -p lib/macos

# Copy built libraries
find bazel-bin -name "*.a" -o -name "*.dylib" | while read lib; do
    cp "$lib" lib/macos/
done

# Copy model files
mkdir -p models
cp mediapipe/modules/hand_landmark/*.tflite models/
cp mediapipe/modules/palm_detection/*.tflite models/

echo "MediaPipe build complete!"
EOF

chmod +x build_hands.sh
./build_hands.sh

# Create CMake config helper
echo "Creating CMake configuration..."
cat > "$PROJECT_ROOT/cmake/MediaPipeConfig.cmake" << EOF
# MediaPipe configuration for CameraGestures
set(MEDIAPIPE_ROOT_DIR "${MEDIAPIPE_DIR}" CACHE PATH "MediaPipe root directory")
set(MEDIAPIPE_INCLUDE_DIR "${MEDIAPIPE_DIR}")
set(MEDIAPIPE_LIB_DIR "${MEDIAPIPE_DIR}/lib/macos")
set(MEDIAPIPE_MODEL_DIR "${MEDIAPIPE_DIR}/models")

# Export model paths
set(MEDIAPIPE_HAND_LANDMARK_MODEL "${MEDIAPIPE_MODEL_DIR}/hand_landmark_lite.tflite")
set(MEDIAPIPE_HAND_DETECTOR_MODEL "${MEDIAPIPE_MODEL_DIR}/palm_detection_lite.tflite")
EOF

echo "MediaPipe setup complete!"
echo "You can now build CameraGestures with MediaPipe support."
