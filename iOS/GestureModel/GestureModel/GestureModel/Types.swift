import Foundation
import HandGestureTypes

// MARK: - Configuration

/// Configuration for GestureModel
public struct GestureModelConfig {
    public let modelPath: String?
    public let backendType: BackendType
    public let predictionThreshold: Float
    public let maxPredictions: Int
    public let enableTemporal: Bool
    public let temporalWindow: TimeInterval
    
    public init(
        modelPath: String? = nil,
        backendType: BackendType = .coreML,
        predictionThreshold: Float = 0.7,
        maxPredictions: Int = 5,
        enableTemporal: Bool = true,
        temporalWindow: TimeInterval = 1.0
    ) {
        self.modelPath = modelPath
        self.backendType = backendType
        self.predictionThreshold = predictionThreshold
        self.maxPredictions = maxPredictions
        self.enableTemporal = enableTemporal
        self.temporalWindow = temporalWindow
    }
    
    public static let defaultConfig = GestureModelConfig()
}

/// Backend types for gesture recognition
public enum BackendType: String, CaseIterable {
    case coreML = "coreml"
    case tensorFlow = "tensorflow" 
    case mock = "mock"
    
    public var displayName: String {
        switch self {
        case .coreML: return "Core ML"
        case .tensorFlow: return "TensorFlow"
        case .mock: return "Mock Backend"
        }
    }
}

// MARK: - Error Types

/// Errors that can occur in GestureModel
public enum GestureModelError: Error {
    case modelNotLoaded
    case invalidModelPath
    case invalidInput
    case predictionFailed
    case trainingFailed
    case unsupportedBackend
    case insufficientData
    
    public var localizedDescription: String {
        switch self {
        case .modelNotLoaded:
            return "Model not loaded"
        case .invalidModelPath:
            return "Invalid model path"
        case .invalidInput:
            return "Invalid input data"
        case .predictionFailed:
            return "Prediction failed"
        case .trainingFailed:
            return "Training failed"
        case .unsupportedBackend:
            return "Unsupported backend"
        case .insufficientData:
            return "Insufficient training data"
        }
    }
}
