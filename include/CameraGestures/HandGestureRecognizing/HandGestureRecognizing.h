#pragma once

#include "CameraGestures/Common/Types.h"
#include <memory>
#include <functional>
#include <string>

namespace CameraGestures {

// Forward declarations
class HandsRecognizing;
class GestureModel;

// Configuration for HandGestureRecognizing
struct HandGestureRecognizingConfig {
    // Camera settings
    int cameraIndex = 0;
    int targetFPS = 30;
    
    // Hand detection settings
    bool detectBothHands = false;
    float minDetectionConfidence = 0.5f;
    float minTrackingConfidence = 0.5f;
    
    // Model settings
    std::string modelPath;
    float predictionThreshold = 0.7f;
    
    // Gesture detection settings
    double minGestureDurationMs = 200.0;  // Minimum duration for valid gesture
    double maxGestureDurationMs = 5000.0;  // Maximum duration for valid gesture
};

// Callback for gesture detection
using GestureDetectedCallback = std::function<void(const GesturePrediction&)>;

class HandGestureRecognizing {
public:
    HandGestureRecognizing();
    ~HandGestureRecognizing();
    
    // Non-copyable
    HandGestureRecognizing(const HandGestureRecognizing&) = delete;
    HandGestureRecognizing& operator=(const HandGestureRecognizing&) = delete;
    
    // Initialize with configuration
    ErrorCode initialize(const HandGestureRecognizingConfig& config);
    
    // Start/stop gesture recognition
    ErrorCode start();
    ErrorCode stop();
    bool isRunning() const;
    
    // Set callback for gesture detection
    void setGestureDetectedCallback(GestureDetectedCallback callback);
    
    // Get supported gestures from loaded model
    std::vector<std::string> getSupportedGestures() const;
    
    // Manual frame processing (for external camera sources)
    ErrorCode processFrame(const uint8_t* frameData, int width, int height, int channels);
    
    // Get current status
    std::string getStatus() const;
    
private:
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

} // namespace CameraGestures
