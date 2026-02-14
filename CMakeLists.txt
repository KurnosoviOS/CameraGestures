cmake_minimum_required(VERSION 3.16)
project(CameraGestures VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Platform-specific settings
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15" CACHE STRING "Minimum OS X deployment version")
    if(IOS)
        set(CMAKE_OSX_ARCHITECTURES "arm64")
        set(CMAKE_OSX_SYSROOT "iphoneos")
    endif()
elseif(ANDROID)
    set(CMAKE_ANDROID_STL_TYPE "c++_shared")
endif()

# Options
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_TESTS "Build unit tests" ON)
option(BUILD_EXAMPLES "Build example applications" ON)
option(USE_TENSORFLOW "Enable TensorFlow backend" ON)
option(USE_SKLEARN "Enable Scikit-learn backend (through sklearn-porter)" OFF)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Find dependencies
find_package(Threads REQUIRED)

# Add custom cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# MediaPipe setup
#find_package(MediaPipe REQUIRED)
#include_directories(${MediaPipe_INCLUDE_DIRS})
#add_definitions(${MediaPipe_DEFINITIONS})

# TensorFlow Lite setup (if enabled)
if(USE_TENSORFLOW)
    # TODO: Add TensorFlow Lite integration
endif()

# Add subdirectories
add_subdirectory(src/HandsRecognizing)
add_subdirectory(src/GestureModel)
add_subdirectory(src/HandGestureRecognizing)

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# Installation rules
install(DIRECTORY include/ DESTINATION include)
install(EXPORT CameraGesturesTargets
    FILE CameraGesturesConfig.cmake
    NAMESPACE CameraGestures::
    DESTINATION lib/cmake/CameraGestures
)

# Package configuration
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CameraGesturesConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)
