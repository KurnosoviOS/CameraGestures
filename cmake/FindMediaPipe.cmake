# FindMediaPipe.cmake
# Finds the MediaPipe library
#
# This will define the following variables:
#   MediaPipe_FOUND - True if MediaPipe was found
#   MediaPipe_INCLUDE_DIRS - MediaPipe include directories
#   MediaPipe_LIBRARIES - Libraries needed to use MediaPipe
#   MediaPipe_DEFINITIONS - Compiler switches required for using MediaPipe

include(FindPackageHandleStandardArgs)

# Allow user to specify MediaPipe root directory
set(MEDIAPIPE_ROOT_DIR "" CACHE PATH "MediaPipe root directory")

# Find MediaPipe include directory
find_path(MediaPipe_INCLUDE_DIR
    NAMES mediapipe/framework/calculator_framework.h
    PATHS
        ${MEDIAPIPE_ROOT_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/mediapipe
        /usr/local/include
        /usr/include
    PATH_SUFFIXES mediapipe
)

# Platform-specific library names and paths
if(APPLE)
    if(IOS)
        set(MEDIAPIPE_LIB_SUFFIX "ios")
        set(MEDIAPIPE_PLATFORM_LIBS
            "-framework AVFoundation"
            "-framework CoreVideo"
            "-framework CoreMedia"
            "-framework CoreGraphics"
            "-framework UIKit"
            "-framework Accelerate"
        )
    else()
        set(MEDIAPIPE_LIB_SUFFIX "macos")
        set(MEDIAPIPE_PLATFORM_LIBS
            "-framework AVFoundation"
            "-framework CoreVideo"
            "-framework CoreMedia"
            "-framework CoreGraphics"
            "-framework Cocoa"
            "-framework Accelerate"
        )
    endif()
elseif(ANDROID)
    set(MEDIAPIPE_LIB_SUFFIX "android")
    set(MEDIAPIPE_PLATFORM_LIBS
        "log"
        "android"
        "EGL"
        "GLESv2"
    )
elseif(WIN32)
    set(MEDIAPIPE_LIB_SUFFIX "windows")
    set(MEDIAPIPE_PLATFORM_LIBS "")
else()
    set(MEDIAPIPE_LIB_SUFFIX "linux")
    set(MEDIAPIPE_PLATFORM_LIBS "")
endif()

# Find MediaPipe libraries
find_library(MediaPipe_FRAMEWORK_LIB
    NAMES mediapipe_framework libmediapipe_framework
    PATHS
        ${MEDIAPIPE_ROOT_DIR}/bazel-bin/mediapipe/framework
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/mediapipe/lib/${MEDIAPIPE_LIB_SUFFIX}
        /usr/local/lib
        /usr/lib
)

find_library(MediaPipe_HANDS_LIB
    NAMES mediapipe_hands libmediapipe_hands hand_landmark_tracking_cpu
    PATHS
        ${MEDIAPIPE_ROOT_DIR}/bazel-bin/mediapipe/modules/hand_landmark
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/mediapipe/lib/${MEDIAPIPE_LIB_SUFFIX}
        /usr/local/lib
        /usr/lib
)

# Find required dependencies
find_package(Protobuf REQUIRED)
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

# Set MediaPipe variables
if(MediaPipe_INCLUDE_DIR AND MediaPipe_FRAMEWORK_LIB)
    set(MediaPipe_FOUND TRUE)
    set(MediaPipe_INCLUDE_DIRS
        ${MediaPipe_INCLUDE_DIR}
        ${MediaPipe_INCLUDE_DIR}/mediapipe
        ${Protobuf_INCLUDE_DIRS}
        ${OpenCV_INCLUDE_DIRS}
        ${EIGEN3_INCLUDE_DIRS}
    )
    set(MediaPipe_LIBRARIES
        ${MediaPipe_FRAMEWORK_LIB}
        ${MediaPipe_HANDS_LIB}
        ${Protobuf_LIBRARIES}
        ${OpenCV_LIBS}
        ${MEDIAPIPE_PLATFORM_LIBS}
    )
    set(MediaPipe_DEFINITIONS
        -DMEDIAPIPE_DISABLE_GPU=1  # Disable GPU for simplicity initially
    )
endif()

find_package_handle_standard_args(MediaPipe
    REQUIRED_VARS MediaPipe_INCLUDE_DIR MediaPipe_FRAMEWORK_LIB
    VERSION_VAR MediaPipe_VERSION
)
