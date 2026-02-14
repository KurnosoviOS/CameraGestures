#pragma once

#include "CameraGestures/Common/Types.h"
#include <memory>
#include <functional>

namespace CameraGestures {

// Forward declarations
class HandDetector;
class HandshotExtractor;
class HandfilmGenerator;

// Configuration for HandsRecognizing module
struct HandsRecognizingConfig {
    int cameraIndex = 0;  // Default camera
    int targetFPS = 30;
    bool detectBothHands = false;  // Single hand by default
    float minDetectionConfidence = 0.5f;
    float minTrackingConfidence = 0.5f;
};

// Callback types
using HandshotCallback = std::function<void(const Handshot&)>;
using HandfilmCallback = std::function<void(const Handfilm&)>;

class HandsRecognizing {
public:
    HandsRecognizing();
    ~HandsRecognizing();
    
    // Non-copyable
    HandsRecognizing(const HandsRecognizing&) = delete;
    HandsRecognizing& operator=(const HandsRecognizing&) = delete;
    
    // Initialize with configuration
    ErrorCode initialize(const HandsRecognizingConfig& config);
    
    // Start/stop hand detection
    ErrorCode start();
    ErrorCode stop();
    bool isRunning() const;
    
    // Set callbacks for real-time processing
    void setHandshotCallback(HandshotCallback callback);
    void setHandfilmCallback(HandfilmCallback callback);
    
    // Manual frame processing (for external camera sources)
    ErrorCode processFrame(const uint8_t* frameData, int width, int height, int channels);
    
    // Get current handfilm buffer
    Handfilm getCurrentHandfilm() const;
    
    // Reset handfilm buffer
    void resetHandfilm();
    
private:
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

} // namespace CameraGestures
