#include "MediaPipeHandTracker.h"
#include <mediapipe/framework/calculator_framework.h>
#include <mediapipe/framework/formats/landmark.pb.h>
#include <mediapipe/framework/formats/image_frame.h>
#include <mediapipe/framework/formats/image_frame_opencv.h>
#include <mediapipe/framework/port/status.h>
#include <mediapipe/framework/port/opencv_imgcodecs_inc.h>
#include <mediapipe/framework/port/opencv_imgproc_inc.h>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <chrono>

namespace CameraGestures {

// MediaPipe graph configuration for hand tracking
constexpr char kHandTrackingGraphConfig[] = R"(
input_stream: "input_video"
output_stream: "hand_landmarks"
output_stream: "hand_world_landmarks"
output_stream: "handedness"

node {
  calculator: "HandLandmarkTrackingCpu"
  input_stream: "IMAGE:input_video"
  output_stream: "LANDMARKS:hand_landmarks"
  output_stream: "WORLD_LANDMARKS:hand_world_landmarks"
  output_stream: "HANDEDNESS:handedness"
  node_options: {
    [type.googleapis.com/mediapipe.HandLandmarkTrackingCalculatorOptions] {
      hand_landmark_model_path: "mediapipe/modules/hand_landmark/hand_landmark_lite.tflite"
      hand_detection_model_path: "mediapipe/modules/hand_landmark/hand_detector.tflite"
      min_detection_confidence: %f
      min_tracking_confidence: %f
      max_num_hands: %d
    }
  }
}
)";

class MediaPipeHandTracker::Impl {
public:
    MediaPipeConfig config;
    std::unique_ptr<mediapipe::CalculatorGraph> graph;
    LandmarkCallback landmarkCallback;
    bool initialized = false;
    
    Impl() = default;
    ~Impl() {
        shutdown();
    }
    
    ErrorCode initialize(const MediaPipeConfig& cfg) {
        config = cfg;
        
        try {
            // Create graph config with parameters
            char configBuffer[4096];
            snprintf(configBuffer, sizeof(configBuffer), kHandTrackingGraphConfig,
                     config.minDetectionConfidence,
                     config.minTrackingConfidence,
                     config.maxNumHands);
            
            mediapipe::CalculatorGraphConfig graphConfig;
            if (!google::protobuf::TextFormat::ParseFromString(configBuffer, &graphConfig)) {
                std::cerr << "Failed to parse graph config" << std::endl;
                return ErrorCode::MEDIAPIPE_INIT_FAILED;
            }
            
            // Create calculator graph
            graph = std::make_unique<mediapipe::CalculatorGraph>();
            auto status = graph->Initialize(graphConfig);
            if (!status.ok()) {
                std::cerr << "Failed to initialize graph: " << status.message() << std::endl;
                return ErrorCode::MEDIAPIPE_INIT_FAILED;
            }
            
            // Set up output stream callback
            status = graph->ObserveOutputStream("hand_landmarks", 
                [this](const mediapipe::Packet& packet) -> mediapipe::Status {
                    onLandmarksReceived(packet);
                    return mediapipe::OkStatus();
                });
            
            if (!status.ok()) {
                std::cerr << "Failed to observe output stream: " << status.message() << std::endl;
                return ErrorCode::MEDIAPIPE_INIT_FAILED;
            }
            
            // Start the graph
            status = graph->StartRun({});
            if (!status.ok()) {
                std::cerr << "Failed to start graph: " << status.message() << std::endl;
                return ErrorCode::MEDIAPIPE_INIT_FAILED;
            }
            
            initialized = true;
            return ErrorCode::SUCCESS;
            
        } catch (const std::exception& e) {
            std::cerr << "Exception during initialization: " << e.what() << std::endl;
            return ErrorCode::MEDIAPIPE_INIT_FAILED;
        }
    }
    
    ErrorCode processFrame(const uint8_t* frameData, int width, int height, int channels) {
        if (!initialized || !graph) {
            return ErrorCode::INVALID_INPUT;
        }
        
        try {
            // Convert raw frame data to MediaPipe ImageFrame
            auto imageFormat = channels == 3 ? mediapipe::ImageFormat::SRGB : mediapipe::ImageFormat::GRAY8;
            auto imageFrame = std::make_unique<mediapipe::ImageFrame>(
                imageFormat, width, height, width * channels, 
                const_cast<uint8_t*>(frameData), [](uint8_t*) {});
            
            // Create packet with timestamp
            auto timestamp = std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now().time_since_epoch()).count();
            
            auto packet = mediapipe::Adopt(imageFrame.release()).At(mediapipe::Timestamp(timestamp));
            
            // Send frame to graph
            auto status = graph->AddPacketToInputStream("input_video", packet);
            if (!status.ok()) {
                std::cerr << "Failed to add packet: " << status.message() << std::endl;
                return ErrorCode::PROCESSING_ERROR;
            }
            
            return ErrorCode::SUCCESS;
            
        } catch (const std::exception& e) {
            std::cerr << "Exception during processing: " << e.what() << std::endl;
            return ErrorCode::PROCESSING_ERROR;
        }
    }
    
    ErrorCode processFrame(const void* cvMatPtr) {
        if (!initialized || !graph || !cvMatPtr) {
            return ErrorCode::INVALID_INPUT;
        }
        
        try {
            const cv::Mat& mat = *static_cast<const cv::Mat*>(cvMatPtr);
            
            // Convert OpenCV Mat to MediaPipe ImageFrame
            auto imageFrame = mediapipe::formats::MatView(&mat);
            
            // Create packet with timestamp
            auto timestamp = std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now().time_since_epoch()).count();
            
            auto packet = mediapipe::MakePacket<mediapipe::ImageFrame>(imageFrame)
                            .At(mediapipe::Timestamp(timestamp));
            
            // Send frame to graph
            auto status = graph->AddPacketToInputStream("input_video", packet);
            if (!status.ok()) {
                std::cerr << "Failed to add packet: " << status.message() << std::endl;
                return ErrorCode::PROCESSING_ERROR;
            }
            
            return ErrorCode::SUCCESS;
            
        } catch (const std::exception& e) {
            std::cerr << "Exception during processing: " << e.what() << std::endl;
            return ErrorCode::PROCESSING_ERROR;
        }
    }
    
    void onLandmarksReceived(const mediapipe::Packet& packet) {
        if (!landmarkCallback) return;
        
        try {
            auto& landmarks = packet.Get<std::vector<mediapipe::NormalizedLandmarkList>>();
            std::vector<Handshot> handshots;
            
            for (const auto& landmarkList : landmarks) {
                Handshot handshot;
                handshot.timestamp = std::chrono::steady_clock::now();
                handshot.confidence = 0.9f; // MediaPipe doesn't provide overall confidence
                
                // Convert MediaPipe landmarks to our format
                for (int i = 0; i < landmarkList.landmark_size() && i < kNumHandLandmarks; ++i) {
                    const auto& landmark = landmarkList.landmark(i);
                    handshot.landmarks[i] = Point3D(
                        landmark.x(),
                        landmark.y(),
                        landmark.z()
                    );
                }
                
                handshots.push_back(handshot);
            }
            
            // Call the callback with detected hands
            if (!handshots.empty()) {
                landmarkCallback(handshots);
            }
            
        } catch (const std::exception& e) {
            std::cerr << "Exception in landmark callback: " << e.what() << std::endl;
        }
    }
    
    void shutdown() {
        if (graph) {
            auto status = graph->CloseAllPacketSources();
            if (!status.ok()) {
                std::cerr << "Failed to close packet sources: " << status.message() << std::endl;
            }
            status = graph->WaitUntilDone();
            if (!status.ok()) {
                std::cerr << "Failed to wait for graph completion: " << status.message() << std::endl;
            }
            graph.reset();
        }
        initialized = false;
    }
};

MediaPipeHandTracker::MediaPipeHandTracker() : pImpl(std::make_unique<Impl>()) {}
MediaPipeHandTracker::~MediaPipeHandTracker() = default;

ErrorCode MediaPipeHandTracker::initialize(const MediaPipeConfig& config) {
    return pImpl->initialize(config);
}

ErrorCode MediaPipeHandTracker::processFrame(const uint8_t* frameData, int width, int height, int channels) {
    return pImpl->processFrame(frameData, width, height, channels);
}

ErrorCode MediaPipeHandTracker::processFrame(const void* cvMatPtr) {
    return pImpl->processFrame(cvMatPtr);
}

void MediaPipeHandTracker::setLandmarkCallback(LandmarkCallback callback) {
    pImpl->landmarkCallback = callback;
}

bool MediaPipeHandTracker::isInitialized() const {
    return pImpl->initialized;
}

void MediaPipeHandTracker::shutdown() {
    pImpl->shutdown();
}

} // namespace CameraGestures
