# GestureModel Module
set(MODULE_NAME GestureModel)

# Source files
set(SOURCES
    GestureModel.cpp
    #GestureModelFactory.cpp
    #TensorFlowBackend.cpp
    #SklearnBackend.cpp
)

# Header files
set(HEADERS
    ${CMAKE_SOURCE_DIR}/include/CameraGestures/GestureModel/GestureModel.h
    #${CMAKE_SOURCE_DIR}/include/CameraGestures/GestureModel/GestureModelFactory.h
    #${CMAKE_SOURCE_DIR}/include/CameraGestures/GestureModel/IGestureBackend.h
    ${CMAKE_SOURCE_DIR}/include/CameraGestures/Common/Types.h
)

# Create library
add_library(${MODULE_NAME} ${SOURCES})

# Include directories
target_include_directories(${MODULE_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link libraries
target_link_libraries(${MODULE_NAME}
    PUBLIC
        Threads::Threads
    PRIVATE
        # TensorFlow Lite libraries will be added here
)

# Compile features
target_compile_features(${MODULE_NAME} PUBLIC cxx_std_17)

# Export target
install(TARGETS ${MODULE_NAME}
    EXPORT CameraGesturesTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/CameraGestures/GestureModel
    DESTINATION include/CameraGestures
)
