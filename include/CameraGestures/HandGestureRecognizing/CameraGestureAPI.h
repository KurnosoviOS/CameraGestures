#ifndef CAMERA_GESTURE_API_H
#define CAMERA_GESTURE_API_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// Export macros
#ifdef _WIN32
    #ifdef CAMERAGESTURES_EXPORTS
        #define CAMERAGESTURES_API __declspec(dllexport)
    #else
        #define CAMERAGESTURES_API __declspec(dllimport)
    #endif
#else
    #define CAMERAGESTURES_API __attribute__((visibility("default")))
#endif

// Error codes
typedef enum {
    CG_SUCCESS = 0,
    CG_ERROR_CAMERA_NOT_AVAILABLE = 1,
    CG_ERROR_MEDIAPIPE_INIT_FAILED = 2,
    CG_ERROR_MODEL_LOAD_FAILED = 3,
    CG_ERROR_INVALID_INPUT = 4,
    CG_ERROR_PROCESSING_ERROR = 5,
    CG_ERROR_NOT_IMPLEMENTED = 6
} CGErrorCode;

// Opaque handle types
typedef struct CGHandGestureRecognizer* CGHandGestureRecognizerRef;

// Gesture prediction structure
typedef struct {
    const char* gestureType;
    float confidence;
} CGGesturePrediction;

// Configuration structure
typedef struct {
    int cameraIndex;
    int targetFPS;
    bool detectBothHands;
    float minDetectionConfidence;
    float minTrackingConfidence;
    const char* modelPath;
    float predictionThreshold;
    double minGestureDurationMs;
    double maxGestureDurationMs;
} CGConfig;

// Callback function type
typedef void (*CGGestureDetectedCallback)(CGGesturePrediction prediction, void* userData);

// Create and destroy recognizer
CAMERAGESTURES_API CGHandGestureRecognizerRef cg_create_recognizer(void);
CAMERAGESTURES_API void cg_destroy_recognizer(CGHandGestureRecognizerRef recognizer);

// Initialize with configuration
CAMERAGESTURES_API CGErrorCode cg_initialize(CGHandGestureRecognizerRef recognizer, const CGConfig* config);

// Start/stop recognition
CAMERAGESTURES_API CGErrorCode cg_start(CGHandGestureRecognizerRef recognizer);
CAMERAGESTURES_API CGErrorCode cg_stop(CGHandGestureRecognizerRef recognizer);
CAMERAGESTURES_API bool cg_is_running(CGHandGestureRecognizerRef recognizer);

// Set callback
CAMERAGESTURES_API void cg_set_gesture_callback(
    CGHandGestureRecognizerRef recognizer,
    CGGestureDetectedCallback callback,
    void* userData
);

// Get supported gestures
CAMERAGESTURES_API int cg_get_supported_gesture_count(CGHandGestureRecognizerRef recognizer);
CAMERAGESTURES_API const char* cg_get_supported_gesture(CGHandGestureRecognizerRef recognizer, int index);

// Process frame manually
CAMERAGESTURES_API CGErrorCode cg_process_frame(
    CGHandGestureRecognizerRef recognizer,
    const uint8_t* frameData,
    int width,
    int height,
    int channels
);

// Get status
CAMERAGESTURES_API const char* cg_get_status(CGHandGestureRecognizerRef recognizer);

// Get error description
CAMERAGESTURES_API const char* cg_get_error_description(CGErrorCode error);

#ifdef __cplusplus
}
#endif

#endif // CAMERA_GESTURE_API_H
