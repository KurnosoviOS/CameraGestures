#pragma once

#include "CameraGestures/Common/Types.h"
#include <memory>
#include <vector>
#include <string>

namespace CameraGestures {

// Forward declaration
class IGestureBackend;

// Configuration for GestureModel
struct GestureModelConfig {
    std::string modelPath;
    std::string backendType = "tensorflow";  // "tensorflow" or "sklearn"
    float predictionThreshold = 0.7f;
    int maxSequenceLength = 100;  // Maximum frames in a handfilm
};

class GestureModel {
public:
    GestureModel();
    ~GestureModel();
    
    // Non-copyable
    GestureModel(const GestureModel&) = delete;
    GestureModel& operator=(const GestureModel&) = delete;
    
    // Initialize with configuration
    ErrorCode initialize(const GestureModelConfig& config);
    
    // Load/save model
    ErrorCode loadModel(const std::string& modelPath);
    ErrorCode saveModel(const std::string& modelPath) const;
    
    // Prediction
    GesturePrediction predict(const Handfilm& handfilm) const;
    std::vector<GesturePrediction> predictTopK(const Handfilm& handfilm, int k = 3) const;
    
    // Get supported gesture types
    std::vector<std::string> getSupportedGestures() const;
    
    // Model information
    std::string getBackendType() const;
    bool isLoaded() const;
    
    // Switch backend (requires reinitialization)
    ErrorCode switchBackend(const std::string& backendType);
    
private:
    class Impl;
    std::unique_ptr<Impl> pImpl;
};

} // namespace CameraGestures
