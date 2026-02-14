#include "CameraGestures/HandGestureRecognizing/CameraGestureAPI.h"
#include "CameraGestures/HandGestureRecognizing/HandGestureRecognizing.h"
#include <memory>
#include <string>
#include <cstring>

using namespace CameraGestures;

// Internal structure to hold C++ object and callback data
struct CGHandGestureRecognizer {
    std::unique_ptr<HandGestureRecognizing> recognizer;
    CGGestureDetectedCallback callback;
    void* userData;
    std::string lastStatus;
    
    CGHandGestureRecognizer() : recognizer(std::make_unique<HandGestureRecognizing>()), 
                                 callback(nullptr), 
                                 userData(nullptr) {}
};

// Helper function to convert ErrorCode to CGErrorCode
static CGErrorCode toCGErrorCode(ErrorCode error) {
    switch (error) {
        case ErrorCode::SUCCESS: return CG_SUCCESS;
        case ErrorCode::CAMERA_NOT_AVAILABLE: return CG_ERROR_CAMERA_NOT_AVAILABLE;
        case ErrorCode::MEDIAPIPE_INIT_FAILED: return CG_ERROR_MEDIAPIPE_INIT_FAILED;
        case ErrorCode::MODEL_LOAD_FAILED: return CG_ERROR_MODEL_LOAD_FAILED;
        case ErrorCode::INVALID_INPUT: return CG_ERROR_INVALID_INPUT;
        case ErrorCode::PROCESSING_ERROR: return CG_ERROR_PROCESSING_ERROR;
        case ErrorCode::NOT_IMPLEMENTED: return CG_ERROR_NOT_IMPLEMENTED;
        default: return CG_ERROR_PROCESSING_ERROR;
    }
}

// Create and destroy recognizer
CGHandGestureRecognizerRef cg_create_recognizer(void) {
    return new CGHandGestureRecognizer();
}

void cg_destroy_recognizer(CGHandGestureRecognizerRef recognizer) {
    delete recognizer;
}

// Initialize with configuration
CGErrorCode cg_initialize(CGHandGestureRecognizerRef recognizer, const CGConfig* config) {
    if (!recognizer || !config || !config->modelPath) {
        return CG_ERROR_INVALID_INPUT;
    }
    
    HandGestureRecognizingConfig cppConfig;
    cppConfig.cameraIndex = config->cameraIndex;
    cppConfig.targetFPS = config->targetFPS;
    cppConfig.detectBothHands = config->detectBothHands;
    cppConfig.minDetectionConfidence = config->minDetectionConfidence;
    cppConfig.minTrackingConfidence = config->minTrackingConfidence;
    cppConfig.modelPath = config->modelPath;
    cppConfig.predictionThreshold = config->predictionThreshold;
    cppConfig.minGestureDurationMs = config->minGestureDurationMs;
    cppConfig.maxGestureDurationMs = config->maxGestureDurationMs;
    
    auto error = recognizer->recognizer->initialize(cppConfig);
    
    // Set up internal callback wrapper
    if (error == ErrorCode::SUCCESS) {
        recognizer->recognizer->setGestureDetectedCallback(
            [recognizer](const GesturePrediction& prediction) {
                if (recognizer->callback) {
                    CGGesturePrediction cgPred;
                    cgPred.gestureType = prediction.gestureType.c_str();
                    cgPred.confidence = prediction.confidence;
                    recognizer->callback(cgPred, recognizer->userData);
                }
            }
        );
    }
    
    return toCGErrorCode(error);
}

// Start/stop recognition
CGErrorCode cg_start(CGHandGestureRecognizerRef recognizer) {
    if (!recognizer) {
        return CG_ERROR_INVALID_INPUT;
    }
    return toCGErrorCode(recognizer->recognizer->start());
}

CGErrorCode cg_stop(CGHandGestureRecognizerRef recognizer) {
    if (!recognizer) {
        return CG_ERROR_INVALID_INPUT;
    }
    return toCGErrorCode(recognizer->recognizer->stop());
}

bool cg_is_running(CGHandGestureRecognizerRef recognizer) {
    if (!recognizer) {
        return false;
    }
    return recognizer->recognizer->isRunning();
}

// Set callback
void cg_set_gesture_callback(
    CGHandGestureRecognizerRef recognizer,
    CGGestureDetectedCallback callback,
    void* userData) {
    if (recognizer) {
        recognizer->callback = callback;
        recognizer->userData = userData;
    }
}

// Get supported gestures
int cg_get_supported_gesture_count(CGHandGestureRecognizerRef recognizer) {
    if (!recognizer) {
        return 0;
    }
    auto gestures = recognizer->recognizer->getSupportedGestures();
    return static_cast<int>(gestures.size());
}

const char* cg_get_supported_gesture(CGHandGestureRecognizerRef recognizer, int index) {
    if (!recognizer || index < 0) {
        return nullptr;
    }
    auto gestures = recognizer->recognizer->getSupportedGestures();
    if (index >= static_cast<int>(gestures.size())) {
        return nullptr;
    }
    return gestures[index].c_str();
}

// Process frame manually
CGErrorCode cg_process_frame(
    CGHandGestureRecognizerRef recognizer,
    const uint8_t* frameData,
    int width,
    int height,
    int channels) {
    if (!recognizer || !frameData) {
        return CG_ERROR_INVALID_INPUT;
    }
    return toCGErrorCode(recognizer->recognizer->processFrame(frameData, width, height, channels));
}

// Get status
const char* cg_get_status(CGHandGestureRecognizerRef recognizer) {
    if (!recognizer) {
        return "Invalid recognizer";
    }
    recognizer->lastStatus = recognizer->recognizer->getStatus();
    return recognizer->lastStatus.c_str();
}

// Get error description
const char* cg_get_error_description(CGErrorCode error) {
    switch (error) {
        case CG_SUCCESS: return "Success";
        case CG_ERROR_CAMERA_NOT_AVAILABLE: return "Camera not available";
        case CG_ERROR_MEDIAPIPE_INIT_FAILED: return "MediaPipe initialization failed";
        case CG_ERROR_MODEL_LOAD_FAILED: return "Model load failed";
        case CG_ERROR_INVALID_INPUT: return "Invalid input";
        case CG_ERROR_PROCESSING_ERROR: return "Processing error";
        case CG_ERROR_NOT_IMPLEMENTED: return "Not implemented";
        default: return "Unknown error";
    }
}
