import Foundation
import Combine
import HandGestureTypes

// MARK: - Response Types

struct UploadExampleResponse: Codable {
    let id: String
    let totalForGesture: Int
}

struct ExampleStatsResponse: Codable {
    struct GestureStat: Codable {
        let gestureId: String
        let count: Int
    }
    let gestures: [GestureStat]
    let total: Int
}

struct TrainingJobResponse: Codable {
    let jobId: String
    let status: String
}

struct ModelStatusResponse: Codable {
    let status: String          // "idle" | "training" | "ready" | "failed"
    let accuracy: Double?
    let trainedOn: Int
    let gestureIds: [String]
    let trainedAt: TimeInterval?
    let error: String?
}

// MARK: - Upload State

enum UploadState: Equatable {
    case idle
    case uploading
    case uploaded(total: Int)
    case failed(String)
}

// MARK: - API Client

/// HTTP client for the gesture recognition training server.
/// All methods currently log their payload to the console instead of sending real requests.
/// Replace the body of each method with a real URLSession call when the server is reachable.
class GestureModelAPIClient: ObservableObject {

    // MARK: - Configuration

    @Published var baseURL: URL {
        didSet {
            UserDefaults.standard.set(baseURL.absoluteString, forKey: Self.baseURLKey)
        }
    }

    private static let baseURLKey = "GestureModelAPIClient.baseURL"
    private static let defaultBaseURL = "http://localhost:8000"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.baseURLKey) ?? Self.defaultBaseURL
        baseURL = URL(string: stored) ?? URL(string: Self.defaultBaseURL)!
    }

    // MARK: - Upload Example

    /// Upload one labelled HandFilm to the server.
    /// Currently logs the JSON payload to the console.
    func uploadExample(_ example: TrainingExample) async throws -> UploadExampleResponse {
        let payload = TrainingExamplePayload(from: example)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(payload),
           let json = String(data: data, encoding: .utf8) {
            print("""
            ──────────────────────────────────────────────
            [GestureModelAPIClient] POST \(baseURL)/examples
            \(json)
            ──────────────────────────────────────────────
            """)
        }

        // Stub response — replace with real URLSession call
        return UploadExampleResponse(id: UUID().uuidString, totalForGesture: 1)
    }

    // MARK: - Example Stats

    /// Fetch per-gesture example counts from the server.
    /// Currently logs the request and returns an empty stub.
    func fetchExampleStats() async throws -> ExampleStatsResponse {
        print("[GestureModelAPIClient] GET \(baseURL)/examples/stats")
        return ExampleStatsResponse(gestures: [], total: 0)
    }

    // MARK: - Trigger Training

    /// Tell the server to start a training job.
    /// Currently logs the request and returns a stub.
    func triggerTraining() async throws -> TrainingJobResponse {
        print("[GestureModelAPIClient] POST \(baseURL)/train")
        return TrainingJobResponse(jobId: UUID().uuidString, status: "started")
    }

    // MARK: - Model Status

    /// Poll the training status on the server.
    /// Currently logs the request and returns an idle stub.
    func fetchModelStatus() async throws -> ModelStatusResponse {
        print("[GestureModelAPIClient] GET \(baseURL)/model/status")
        return ModelStatusResponse(
            status: "idle",
            accuracy: nil,
            trainedOn: 0,
            gestureIds: [],
            trainedAt: nil,
            error: nil
        )
    }

    // MARK: - Download Model

    /// Download the latest .tflite model from the server and save it to
    /// Documents/GestureModel/gesture_model.tflite.
    /// Currently logs the request and returns a stub URL.
    func downloadModel() async throws -> URL {
        print("[GestureModelAPIClient] GET \(baseURL)/model/download")
        let dest = modelFileURL()
        print("[GestureModelAPIClient] Would write model to \(dest.path)")
        return dest
    }

    // MARK: - Helpers

    private func modelFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs
            .appendingPathComponent("GestureModel", isDirectory: true)
            .appendingPathComponent("gesture_model.tflite")
    }
}

// MARK: - Request Payload

/// Codable wrapper for TrainingExample to send over the network.
/// HandGestureTypes structs are not Codable by design; this wrapper lives in the app target.
private struct TrainingExamplePayload: Encodable {
    let handFilm: HandFilmPayload
    let gestureId: String
    let sessionId: String
    let userId: String?

    init(from example: TrainingExample) {
        handFilm = HandFilmPayload(from: example.handfilm)
        gestureId = example.gestureId
        sessionId = example.sessionId
        userId = example.userId
    }
}

private struct HandFilmPayload: Encodable {
    let frames: [HandShotPayload]
    let startTime: TimeInterval

    init(from film: HandFilm) {
        frames = film.frames.map { HandShotPayload(from: $0) }
        startTime = film.startTime
    }
}

private struct HandShotPayload: Encodable {
    let landmarks: [Point3DPayload]
    let timestamp: TimeInterval
    let leftOrRight: String

    init(from shot: HandShot) {
        landmarks = shot.landmarks.map { Point3DPayload(from: $0) }
        timestamp = shot.timestamp
        leftOrRight = {
            switch shot.leftOrRight {
            case .left: return "left"
            case .right: return "right"
            case .unknown: return "unknown"
            }
        }()
    }
}

private struct Point3DPayload: Encodable {
    let x: Float
    let y: Float
    let z: Float

    init(from point: Point3D) {
        x = point.x; y = point.y; z = point.z
    }
}
