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
    @StateObject private var gestureRegistry = GestureRegistry()

    // MARK: - Scene Configuration

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gestureRecognizer)
                .environmentObject(trainingDataManager)
                .environmentObject(appSettings)
                .environmentObject(gestureRegistry)
                .preferredColorScheme(appSettings.colorScheme)
        }
    }
}

// MARK: - Training Data Manager

class TrainingDataManager: ObservableObject {
    @Published var currentDataset: TrainingDataset?
    @Published var trainingExamples: [TrainingExample] = []
    @Published var isCollecting = false
    @Published var currentGestureId: String?
    @Published var trainingState: TrainingState = .idle

    // MARK: - Data Collection

    func startDataCollection(for gesture: GestureDefinition) {
        currentGestureId = gesture.id
        isCollecting = true
    }

    func stopDataCollection() {
        isCollecting = false
        currentGestureId = nil
    }

    func addTrainingExample(_ example: TrainingExample) {
        trainingExamples.append(example)
        // Keep currentDataset in sync
        if currentDataset != nil {
            currentDataset?.addExample(example)
        }
        objectWillChange.send()
    }

    func createNewDataset(name: String) {
        var dataset = TrainingDataset(name: name)
        for example in trainingExamples {
            dataset.addExample(example)
        }
        currentDataset = dataset
    }

    // MARK: - Persistence

    /// Serialize the current dataset (and all training examples) to Documents.
    func saveDataset() {
        guard let dataset = currentDataset else { return }
        let url = datasetFileURL(name: dataset.name)
        do {
            let dto = TrainingDatasetDTO(from: dataset)
            let data = try JSONEncoder().encode(dto)
            let dir = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            print("TrainingDataManager: failed to save dataset — \(error)")
        }
    }

    /// Load a previously saved dataset from Documents.
    func loadDataset(name: String) {
        let url = datasetFileURL(name: name)
        guard let data = try? Data(contentsOf: url),
              let dto = try? JSONDecoder().decode(TrainingDatasetDTO.self, from: data) else {
            return
        }
        let dataset = dto.toTrainingDataset()
        currentDataset = dataset
        trainingExamples = dataset.examples
    }

    /// All dataset names currently saved on disk.
    func savedDatasetNames() -> [String] {
        let dir = datasetsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }
        return files
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    // MARK: - File Paths

    private func datasetsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrainingDatasets", isDirectory: true)
    }

    private func datasetFileURL(name: String) -> URL {
        datasetsDirectory().appendingPathComponent("\(name).json")
    }
}

// MARK: - Training State

enum TrainingState: Equatable {
    case idle
    case training
    case done(ModelMetrics)
    case failed(String)

    static func == (lhs: TrainingState, rhs: TrainingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.training, .training): return true
        case (.done, .done): return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
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

    @Published var cameraConfig = HandsRecognizingConfig.defaultConfig
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
        let compiledModelURL = defaultCompiledModelURL()
        let modelPath = FileManager.default.fileExists(atPath: compiledModelURL.path)
            ? compiledModelURL.path
            : nil
        modelConfig = GestureModelConfig(
            modelPath: modelPath,
            backendType: modelPath != nil ? .tensorFlow : .mock,
            predictionThreshold: confidenceThreshold,
            maxPredictions: 5
        )
    }

    private func defaultCompiledModelURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GestureModel/GestureModel.mlmodelc", isDirectory: true)
    }
}

// MARK: - Gesture Recognizer Wrapper

@MainActor
class GestureRecognizerWrapper: ObservableObject {
    let recognizer: HandGestureRecognizing

    @Published var isRecognizing: Bool = false
    @Published var currentGesture: String?
    @Published var confidence: Float = 0.0
    @Published var lastError: String?

    init(recognizer: HandGestureRecognizing) {
        self.recognizer = recognizer
    }
}

// MARK: - DTOs for JSON Serialization

/// DTO for Point3D (HandGestureTypes is not Codable to keep it dependency-free).
struct Point3DDTO: Codable {
    let x: Float
    let y: Float
    let z: Float

    init(from point: Point3D) {
        x = point.x; y = point.y; z = point.z
    }

    func toPoint3D() -> Point3D { Point3D(x: x, y: y, z: z) }
}

struct HandShotDTO: Codable {
    let landmarks: [Point3DDTO]
    let timestamp: TimeInterval
    let leftOrRight: String   // "left" | "right" | "unknown"

    init(from handShot: HandShot) {
        landmarks = handShot.landmarks.map { Point3DDTO(from: $0) }
        timestamp = handShot.timestamp
        leftOrRight = {
            switch handShot.leftOrRight {
            case .left: return "left"
            case .right: return "right"
            case .unknown: return "unknown"
            }
        }()
    }

    func toHandShot() -> HandShot {
        let side: LeftOrRight = leftOrRight == "left" ? .left : leftOrRight == "right" ? .right : .unknown
        return HandShot(
            landmarks: landmarks.map { $0.toPoint3D() },
            timestamp: timestamp,
            leftOrRight: side
        )
    }
}

struct HandFilmDTO: Codable {
    let frames: [HandShotDTO]
    let startTime: TimeInterval

    init(from handFilm: HandFilm) {
        frames = handFilm.frames.map { HandShotDTO(from: $0) }
        startTime = handFilm.startTime
    }

    func toHandFilm() -> HandFilm {
        var film = HandFilm(startTime: startTime)
        frames.map { $0.toHandShot() }.forEach { film.addFrame($0) }
        return film
    }
}

struct TrainingExampleDTO: Codable {
    let handfilm: HandFilmDTO
    let gestureId: String
    let userId: String?
    let sessionId: String
    let timestamp: TimeInterval

    init(from example: TrainingExample) {
        handfilm = HandFilmDTO(from: example.handfilm)
        gestureId = example.gestureId
        userId = example.userId
        sessionId = example.sessionId
        timestamp = example.timestamp
    }

    func toTrainingExample() -> TrainingExample {
        TrainingExample(
            handfilm: handfilm.toHandFilm(),
            gestureId: gestureId,
            userId: userId,
            sessionId: sessionId
        )
    }
}

struct TrainingDatasetDTO: Codable {
    let name: String
    let createdAt: TimeInterval
    let examples: [TrainingExampleDTO]

    init(from dataset: TrainingDataset) {
        name = dataset.name
        createdAt = dataset.createdAt
        examples = dataset.examples.map { TrainingExampleDTO(from: $0) }
    }

    func toTrainingDataset() -> TrainingDataset {
        var dataset = TrainingDataset(name: name)
        examples.map { $0.toTrainingExample() }.forEach { dataset.addExample($0) }
        return dataset
    }
}
