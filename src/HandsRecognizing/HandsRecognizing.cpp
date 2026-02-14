#include "CameraGestures/HandsRecognizing/HandsRecognizing.h"
#include "MediaPipeHandTracker.h"
#include <thread>
#include <atomic>
#include <mutex>
#include <iostream>
#include <opencv2/opencv.hpp>

namespace CameraGestures {

class HandsRecognizing::Impl {
public:
    HandsRecognizingConfig config;
    std::atomic<bool> running{false};
    std::thread processingThread;
    
    HandshotCallback handshotCallback;
    HandfilmCallback handfilmCallback;
    
    Handfilm currentHandfilm;
    mutable std::mutex handfilmMutex;
    
    // MediaPipe hand tracker
    std::unique_ptr<MediaPipeHandTracker> handTracker;
    
    // Camera capture
    cv::VideoCapture camera;
    
    Impl() = default;
    ~Impl() {
        stop();
    }
    
    ErrorCode initialize(const HandsRecognizingConfig& cfg) {
        config = cfg;
        
        // Initialize MediaPipe hand tracker
        handTracker = std::make_unique<MediaPipeHandTracker>();
        MediaPipeConfig mpConfig;
        mpConfig.maxNumHands = config.detectBothHands ? 2 : 1;
        mpConfig.minDetectionConfidence = config.minDetectionConfidence;
        mpConfig.minTrackingConfidence = config.minTrackingConfidence;
        
        auto error = handTracker->initialize(mpConfig);
        if (error != ErrorCode::SUCCESS) {
            std::cerr << "Failed to initialize MediaPipe hand tracker" << std::endl;
            return error;
        }
        
        // Set up landmark callback
        handTracker->setLandmarkCallback(
            [this](const std::vector<Handshot>& handshots) {
                onHandshotsReceived(handshots);
            }
        );
        
        // Initialize camera
        camera.open(config.cameraIndex);
        if (!camera.isOpened()) {
            std::cerr << "Failed to open camera " << config.cameraIndex << std::endl;
            return ErrorCode::CAMERA_NOT_AVAILABLE;
        }
        
        // Set camera properties
        camera.set(cv::CAP_PROP_FPS, config.targetFPS);
        camera.set(cv::CAP_PROP_FRAME_WIDTH, 640);
        camera.set(cv::CAP_PROP_FRAME_HEIGHT, 480);
        
        return ErrorCode::SUCCESS;
    }
    
    ErrorCode start() {
        if (running) {
            return ErrorCode::SUCCESS;
        }
        
        running = true;
        processingThread = std::thread([this]() {
            processLoop();
        });
        
        return ErrorCode::SUCCESS;
    }
    
    ErrorCode stop() {
        if (!running) {
            return ErrorCode::SUCCESS;
        }
        
        running = false;
        if (processingThread.joinable()) {
            processingThread.join();
        }
        
        // Clean up camera
        if (camera.isOpened()) {
            camera.release();
        }
        
        // Shutdown MediaPipe
        if (handTracker) {
            handTracker->shutdown();
        }
        
        return ErrorCode::SUCCESS;
    }
    
    void processLoop() {
        cv::Mat frame;
        
        while (running) {
            // Capture frame from camera
            if (!camera.read(frame)) {
                std::cerr << "Failed to read frame from camera" << std::endl;
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }
            
            // Process frame with MediaPipe
            auto error = handTracker->processFrame(&frame);
            if (error != ErrorCode::SUCCESS) {
                std::cerr << "Failed to process frame" << std::endl;
            }
            
            // Frame rate limiting (if needed)
            std::this_thread::sleep_for(std::chrono::milliseconds(1000 / config.targetFPS));
        }
    }
    
    ErrorCode processFrame(const uint8_t* frameData, int width, int height, int channels) {
        if (!handTracker || !handTracker->isInitialized()) {
            return ErrorCode::INVALID_INPUT;
        }
        
        return handTracker->processFrame(frameData, width, height, channels);
    }
    
    void onHandshotsReceived(const std::vector<Handshot>& handshots) {
        // Process each detected hand
        for (const auto& handshot : handshots) {
            // Call handshot callback if set
            if (handshotCallback) {
                handshotCallback(handshot);
            }
            
            // Update current handfilm
            {
                std::lock_guard<std::mutex> lock(handfilmMutex);
                currentHandfilm.frames.push_back(handshot);
                
                // Check if handfilm is ready (e.g., based on duration or gesture completion)
                if (currentHandfilm.getDurationMs() > 500.0) { // Simple duration check
                    if (handfilmCallback && currentHandfilm.frames.size() > 10) {
                        handfilmCallback(currentHandfilm);
                    }
                    // Start new handfilm
                    currentHandfilm.clear();
                }
            }
        }
    }
};

HandsRecognizing::HandsRecognizing() : pImpl(std::make_unique<Impl>()) {}
HandsRecognizing::~HandsRecognizing() = default;

ErrorCode HandsRecognizing::initialize(const HandsRecognizingConfig& config) {
    return pImpl->initialize(config);
}

ErrorCode HandsRecognizing::start() {
    return pImpl->start();
}

ErrorCode HandsRecognizing::stop() {
    return pImpl->stop();
}

bool HandsRecognizing::isRunning() const {
    return pImpl->running;
}

void HandsRecognizing::setHandshotCallback(HandshotCallback callback) {
    pImpl->handshotCallback = callback;
}

void HandsRecognizing::setHandfilmCallback(HandfilmCallback callback) {
    pImpl->handfilmCallback = callback;
}

ErrorCode HandsRecognizing::processFrame(const uint8_t* frameData, int width, int height, int channels) {
    return pImpl->processFrame(frameData, width, height, channels);
}

Handfilm HandsRecognizing::getCurrentHandfilm() const {
    std::lock_guard<std::mutex> lock(pImpl->handfilmMutex);
    return pImpl->currentHandfilm;
}

void HandsRecognizing::resetHandfilm() {
    std::lock_guard<std::mutex> lock(pImpl->handfilmMutex);
    pImpl->currentHandfilm.clear();
}

} // namespace CameraGestures
