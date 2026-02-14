#pragma once

#include <vector>
#include <array>
#include <chrono>
#include <string>
#include <memory>

namespace CameraGestures {

// 3D coordinate point
struct Point3D {
    float x;
    float y;
    float z;
    
    Point3D() : x(0), y(0), z(0) {}
    Point3D(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}
};

// MediaPipe hand landmark indices
enum class HandLandmark : int {
    WRIST = 0,
    THUMB_CMC = 1,
    THUMB_MCP = 2,
    THUMB_IP = 3,
    THUMB_TIP = 4,
    INDEX_FINGER_MCP = 5,
    INDEX_FINGER_PIP = 6,
    INDEX_FINGER_DIP = 7,
    INDEX_FINGER_TIP = 8,
    MIDDLE_FINGER_MCP = 9,
    MIDDLE_FINGER_PIP = 10,
    MIDDLE_FINGER_DIP = 11,
    MIDDLE_FINGER_TIP = 12,
    RING_FINGER_MCP = 13,
    RING_FINGER_PIP = 14,
    RING_FINGER_DIP = 15,
    RING_FINGER_TIP = 16,
    PINKY_MCP = 17,
    PINKY_PIP = 18,
    PINKY_DIP = 19,
    PINKY_TIP = 20
};

constexpr int kNumHandLandmarks = 21;

// Handshot: 21 3D coordinates of hand landmarks at a specific moment
struct Handshot {
    std::array<Point3D, kNumHandLandmarks> landmarks;
    std::chrono::steady_clock::time_point timestamp;
    float confidence = 0.0f;  // Overall detection confidence
    
    Handshot() = default;
};

// Handfilm: Time-ordered sequence of handshots representing a gesture
struct Handfilm {
    std::vector<Handshot> frames;
    std::string gestureLabel;  // Optional label for training
    
    // Helper methods
    void clear() { frames.clear(); }
    bool empty() const { return frames.empty(); }
    size_t size() const { return frames.size(); }
    
    // Get duration in milliseconds
    double getDurationMs() const {
        if (frames.size() < 2) return 0.0;
        auto duration = frames.back().timestamp - frames.front().timestamp;
        return std::chrono::duration<double, std::milli>(duration).count();
    }
};

// Gesture prediction result
struct GesturePrediction {
    std::string gestureType;
    float confidence;
    
    GesturePrediction() : confidence(0.0f) {}
    GesturePrediction(const std::string& type, float conf) 
        : gestureType(type), confidence(conf) {}
};

// Error codes
enum class ErrorCode {
    SUCCESS = 0,
    CAMERA_NOT_AVAILABLE = 1,
    MEDIAPIPE_INIT_FAILED = 2,
    MODEL_LOAD_FAILED = 3,
    INVALID_INPUT = 4,
    PROCESSING_ERROR = 5,
    NOT_IMPLEMENTED = 6
};

} // namespace CameraGestures
