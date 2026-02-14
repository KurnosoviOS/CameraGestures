#include "CameraGestures/HandGestureRecognizing/HandGestureRecognizing.h"
#include "CameraGestures/HandsRecognizing/HandsRecognizing.h"
#include "CameraGestures/GestureModel/GestureModel.h"
#include <mutex>
#include <queue>

namespace CameraGestures {

class HandGestureRecognizing::Impl {
public:
    HandGestureRecognizingConfig config;
    std::unique_ptr<HandsRecognizing> handsRecognizer;
    std::unique_ptr<GestureModel> gestureModel;
    
    GestureDetectedCallback gestureCallback;
    std::mutex callbackMutex;
    
    // Gesture detection state
    Handfilm currentGesture;
    std::chrono::steady_clock::time_point gestureStartTime;
    bool isCollectingGesture = false;
    
    Impl() = default;
    
    ErrorCode initialize(const HandGestureRecognizingConfig& cfg) {
        config = cfg;
        
        // Initialize HandsRecognizing
        handsRecognizer = std::make_unique<HandsRecognizing>();
        HandsRecognizingConfig handsConfig;
        handsConfig.cameraIndex = config.cameraIndex;
        handsConfig.targetFPS = config.targetFPS;
        handsConfig.detectBothHands = config.detectBothHands;
        handsConfig.minDetectionConfidence = config.minDetectionConfidence;
        handsConfig.minTrackingConfidence = config.minTrackingConfidence;
        
        auto error = handsRecognizer->initialize(handsConfig);
        if (error != ErrorCode::SUCCESS) {
            return error;
        }
        
        // Initialize GestureModel
        gestureModel = std::make_unique<GestureModel>();
        GestureModelConfig modelConfig;
        modelConfig.modelPath = config.modelPath;
        modelConfig.predictionThreshold = config.predictionThreshold;
        
        error = gestureModel->initialize(modelConfig);
        if (error != ErrorCode::SUCCESS) {
            return error;
        }
        
        // Set up callbacks
        handsRecognizer->setHandshotCallback(
            [this](const Handshot& handshot) { onHandshotReceived(handshot); }
        );
        
        return ErrorCode::SUCCESS;
    }
    
    ErrorCode start() {
        return handsRecognizer->start();
    }
    
    ErrorCode stop() {
        return handsRecognizer->stop();
    }
    
    bool isRunning() const {
        return handsRecognizer->isRunning();
    }
    
    void onHandshotReceived(const Handshot& handshot) {
        auto now = std::chrono::steady_clock::now();
        
        // Start new gesture if needed
        if (!isCollectingGesture || currentGesture.empty()) {
            currentGesture.clear();
            gestureStartTime = now;
            isCollectingGesture = true;
        }
        
        // Add handshot to current gesture
        currentGesture.frames.push_back(handshot);
        
        // Check if gesture is complete
        double durationMs = currentGesture.getDurationMs();
        
        if (durationMs >= config.minGestureDurationMs) {
            // Try to recognize gesture
            auto prediction = gestureModel->predict(currentGesture);
            
            if (!prediction.gestureType.empty() && 
                prediction.confidence >= config.predictionThreshold) {
                // Gesture detected!
                {
                    std::lock_guard<std::mutex> lock(callbackMutex);
                    if (gestureCallback) {
                        gestureCallback(prediction);
                    }
                }
                
                // Reset for next gesture
                currentGesture.clear();
                isCollectingGesture = false;
            } else if (durationMs >= config.maxGestureDurationMs) {
                // Gesture too long, reset
                currentGesture.clear();
                isCollectingGesture = false;
            }
        }
    }
    
    std::vector<std::string> getSupportedGestures() const {
        return gestureModel->getSupportedGestures();
    }
    
    ErrorCode processFrame(const uint8_t* frameData, int width, int height, int channels) {
        return handsRecognizer->processFrame(frameData, width, height, channels);
    }
    
    std::string getStatus() const {
        if (!handsRecognizer->isRunning()) {
            return "Stopped";
        }
        if (!gestureModel->isLoaded()) {
            return "Model not loaded";
        }
        if (isCollectingGesture) {
            return "Collecting gesture";
        }
        return "Ready";
    }
};

HandGestureRecognizing::HandGestureRecognizing() : pImpl(std::make_unique<Impl>()) {}
HandGestureRecognizing::~HandGestureRecognizing() = default;

ErrorCode HandGestureRecognizing::initialize(const HandGestureRecognizingConfig& config) {
    return pImpl->initialize(config);
}

ErrorCode HandGestureRecognizing::start() {
    return pImpl->start();
}

ErrorCode HandGestureRecognizing::stop() {
    return pImpl->stop();
}

bool HandGestureRecognizing::isRunning() const {
    return pImpl->isRunning();
}

void HandGestureRecognizing::setGestureDetectedCallback(GestureDetectedCallback callback) {
    std::lock_guard<std::mutex> lock(pImpl->callbackMutex);
    pImpl->gestureCallback = callback;
}

std::vector<std::string> HandGestureRecognizing::getSupportedGestures() const {
    return pImpl->getSupportedGestures();
}

ErrorCode HandGestureRecognizing::processFrame(const uint8_t* frameData, int width, int height, int channels) {
    return pImpl->processFrame(frameData, width, height, channels);
}

std::string HandGestureRecognizing::getStatus() const {
    return pImpl->getStatus();
}

} // namespace CameraGestures
