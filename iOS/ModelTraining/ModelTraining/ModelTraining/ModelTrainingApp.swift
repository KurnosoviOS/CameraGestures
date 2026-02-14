import SwiftUI
import HandGestureTypes
import HandsRecognizingModule
import GestureModelModule
import HandGestureRecognizingFramework
import Combine

@main
struct ModelTrainingApp: App {
    
    // MARK: - State Management
    
    @StateObject private var gestureRecognizer = GestureRecognizerWrapper(recognizer: HandGestureRecognizing())
    @StateObject private var trainingDataManager = TrainingDataManager()
    @StateObject private var appSettings = AppSettings()
    
    // MARK: - Scene Configuration
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gestureRecognizer)
                .environmentObject(trainingDataManager)
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.colorScheme)
        }
    }
}

// MARK: - Training Data Manager

class TrainingDataManager: ObservableObject {
    @Published var currentDataset: TrainingDataset?
    @Published var trainingExamples: [TrainingExample] = []
    @Published var isCollecting = false
    @Published var currentGestureType: GestureType?
    
    func startDataCollection(for gestureType: GestureType) {
        currentGestureType = gestureType
        isCollecting = true
    }
    
    func stopDataCollection() {
        isCollecting = false
        currentGestureType = nil
    }
    
    func addTrainingExample(_ example: TrainingExample) {
        trainingExamples.append(example)
        objectWillChange.send()
    }
    
    func createNewDataset(name: String) {
        currentDataset = TrainingDataset(name: name)
    }
    
    func saveDataset() {
        // In real implementation, would save to Core Data or files
        print("Saving dataset: \(currentDataset?.name ?? "Unknown")")
    }
    
    func loadDataset(name: String) {
        // In real implementation, would load from storage
        currentDataset = MockData.mockTrainingDataset(name: name)
    }
}

// MARK: - App Settings

class AppSettings: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    @Published var preferredCamera: Int = 0
    @Published var targetFPS: Int = 30
    @Published var confidenceThreshold: Float = 0.7
    @Published var enableHapticFeedback = true
    @Published var showDebugInfo = false
    
    // Camera settings
    @Published var cameraConfig = HandsRecognizingConfig.defaultConfig
    
    // Model settings  
    @Published var modelConfig = GestureModelConfig.defaultConfig
    
    func updateCameraConfig() {
        cameraConfig = HandsRecognizingConfig(
            cameraIndex: preferredCamera,
            targetFPS: targetFPS,
            detectBothHands: true,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5
        )
    }
    
    func updateModelConfig() {
        modelConfig = GestureModelConfig(
            modelPath: nil,
            backendType: .mock,
            predictionThreshold: confidenceThreshold,
            maxPredictions: 5
        )
    }
}

@MainActor
class GestureRecognizerWrapper: ObservableObject {
    let recognizer: HandGestureRecognizing
    
    // Published properties for UI updates
    @Published var isRecognizing: Bool = false
    @Published var currentGesture: String?
    @Published var confidence: Float = 0.0
    @Published var lastError: String?
    
    init(recognizer: HandGestureRecognizing) {
        self.recognizer = recognizer
    }
    
    func processFrame() {
        // Process frame and update published properties
        // let result = recognizer.processCurrentFrame()
        // currentGesture = result.gestureName
        // confidence = result.confidence
    }
    
    // Add other methods as needed to interface with your C++ class
}
