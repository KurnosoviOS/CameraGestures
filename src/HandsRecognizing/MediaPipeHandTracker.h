#pragma once

#include "CameraGestures/Common/Types.h"
#include <memory>
#include <vector>
#include <functional>

// Forward declarations for MediaPipe types
namespace mediapipe {
class CalculatorGraph;
class Packet;
}

namespace CameraGestures {

// Configuration for MediaPipe hand tracker
struct MediaPipeConfig {
    bool useGPU = false;
    int maxNumHands = 1;
    float minDetectionConfidence = 0.5f;
    float minTrackingConfidence = 0.5f;
    std::string modelPath = "";  // Path to hand tracking model files
};

// Callback for processed hand landmarks
using LandmarkCallback = std::function<void(const std::vector<Handshot>&)>;

class MediaPipeHandTracker {
public:
    MediaPipeHandTracker();
    ~MediaPipeHandTracker();
    
    // Non-copyable
    MediaPipeHandTracker(const MediaPipeHandTracker&) = delete;
    MediaPipeHandTracker& operator=(const MediaPipeHandTracker&) = delete;
    
    // Initialize with configuration
    ErrorCode initialize(const MediaPipeConfig& config);
    
    // Process a single frame
    ErrorCode processFrame(const uint8_t* frameData, int width, int height, int channels);
    
    // Process with OpenCV Mat (if available)
    ErrorCode processFrame(const void* cvMatPtr);
    
    // Set callback for receiving hand landmarks
    void setLandmarkCallback(LandmarkCallback callback);
    
    // Check if initialized
    bool isInitialized() const;
    
    // Shutdown and cleanup
    void shutdown();
    
private:
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

} // namespace CameraGestures
