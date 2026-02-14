#include "CameraGestures/GestureModel/GestureModel.h"
#include <unordered_map>
#include <algorithm>

namespace CameraGestures {

// Interface for different ML backends
class IGestureBackend {
public:
    virtual ~IGestureBackend() = default;
    
    virtual ErrorCode loadModel(const std::string& modelPath) = 0;
    virtual ErrorCode saveModel(const std::string& modelPath) const = 0;
    virtual std::vector<GesturePrediction> predict(const Handfilm& handfilm) const = 0;
    virtual std::vector<std::string> getSupportedGestures() const = 0;
    virtual bool isLoaded() const = 0;
};

class GestureModel::Impl {
public:
    GestureModelConfig config;
    std::unique_ptr<IGestureBackend> backend;
    
    Impl() = default;
    
    ErrorCode initialize(const GestureModelConfig& cfg) {
        config = cfg;
        
        // Create appropriate backend
        if (config.backendType == "tensorflow") {
            // TODO: Create TensorFlow backend
            // backend = std::make_unique<TensorFlowBackend>();
        } else if (config.backendType == "sklearn") {
            // TODO: Create Sklearn backend
            // backend = std::make_unique<SklearnBackend>();
        } else {
            return ErrorCode::INVALID_INPUT;
        }
        
        // Load model if path provided
        if (!config.modelPath.empty()) {
            return loadModel(config.modelPath);
        }
        
        return ErrorCode::SUCCESS;
    }
    
    ErrorCode loadModel(const std::string& modelPath) {
        if (!backend) {
            return ErrorCode::INVALID_INPUT;
        }
        return backend->loadModel(modelPath);
    }
    
    ErrorCode saveModel(const std::string& modelPath) const {
        if (!backend) {
            return ErrorCode::INVALID_INPUT;
        }
        return backend->saveModel(modelPath);
    }
    
    GesturePrediction predict(const Handfilm& handfilm) const {
        if (!backend || !backend->isLoaded()) {
            return GesturePrediction();
        }
        
        auto predictions = backend->predict(handfilm);
        if (predictions.empty()) {
            return GesturePrediction();
        }
        
        // Return top prediction above threshold
        if (predictions[0].confidence >= config.predictionThreshold) {
            return predictions[0];
        }
        
        return GesturePrediction();
    }
    
    std::vector<GesturePrediction> predictTopK(const Handfilm& handfilm, int k) const {
        if (!backend || !backend->isLoaded()) {
            return {};
        }
        
        auto predictions = backend->predict(handfilm);
        
        // Sort by confidence
        std::sort(predictions.begin(), predictions.end(),
                  [](const auto& a, const auto& b) { return a.confidence > b.confidence; });
        
        // Return top k
        if (predictions.size() > static_cast<size_t>(k)) {
            predictions.resize(k);
        }
        
        return predictions;
    }
};

GestureModel::GestureModel() : pImpl(std::make_unique<Impl>()) {}
GestureModel::~GestureModel() = default;

ErrorCode GestureModel::initialize(const GestureModelConfig& config) {
    return pImpl->initialize(config);
}

ErrorCode GestureModel::loadModel(const std::string& modelPath) {
    return pImpl->loadModel(modelPath);
}

ErrorCode GestureModel::saveModel(const std::string& modelPath) const {
    return pImpl->saveModel(modelPath);
}

GesturePrediction GestureModel::predict(const Handfilm& handfilm) const {
    return pImpl->predict(handfilm);
}

std::vector<GesturePrediction> GestureModel::predictTopK(const Handfilm& handfilm, int k) const {
    return pImpl->predictTopK(handfilm, k);
}

std::vector<std::string> GestureModel::getSupportedGestures() const {
    if (!pImpl->backend) {
        return {};
    }
    return pImpl->backend->getSupportedGestures();
}

std::string GestureModel::getBackendType() const {
    return pImpl->config.backendType;
}

bool GestureModel::isLoaded() const {
    return pImpl->backend && pImpl->backend->isLoaded();
}

ErrorCode GestureModel::switchBackend(const std::string& backendType) {
    pImpl->config.backendType = backendType;
    return pImpl->initialize(pImpl->config);
}

} // namespace CameraGestures
