# HandGestureRecognizing Module
set(MODULE_NAME HandGestureRecognizing)

# Source files
set(SOURCES
    HandGestureRecognizing.cpp
    CameraGestureAPI.cpp
)

# Header files
set(HEADERS
    ${CMAKE_SOURCE_DIR}/include/CameraGestures/HandGestureRecognizing/HandGestureRecognizing.h
    ${CMAKE_SOURCE_DIR}/include/CameraGestures/HandGestureRecognizing/CameraGestureAPI.h
    ${CMAKE_SOURCE_DIR}/include/CameraGestures/Common/Types.h
)

# Create library (this will be the main binary library exported)
add_library(${MODULE_NAME} ${SOURCES})

# Include directories
target_include_directories(${MODULE_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link internal libraries
target_link_libraries(${MODULE_NAME}
    PRIVATE
        HandsRecognizing
        GestureModel
        Threads::Threads
)

# Compile features
target_compile_features(${MODULE_NAME} PUBLIC cxx_std_17)

# Platform-specific export settings
if(WIN32)
    target_compile_definitions(${MODULE_NAME} PRIVATE CAMERAGESTURES_EXPORTS)
endif()

# Export target
install(TARGETS ${MODULE_NAME}
    EXPORT CameraGesturesTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/CameraGestures/HandGestureRecognizing
    DESTINATION include/CameraGestures
)

# Install C API header separately for easier access
install(FILES ${CMAKE_SOURCE_DIR}/include/CameraGestures/HandGestureRecognizing/CameraGestureAPI.h
    DESTINATION include
)
