import Foundation
import HandGestureTypes

/// Mock data generator for GestureModel framework
public enum MockData {

    // MARK: - Mock Predictions

    /// Returns an empty list — no heuristic predictions without a trained model.
    public static func mockPredictions() -> [GesturePrediction] {
        return []
    }

    /// Generate a single unknown prediction (used when no model is loaded)
    public static func unknownPrediction() -> GesturePrediction {
        return GesturePrediction(
            gestureId: "unknown",
            gestureName: "Unknown",
            confidence: 0.0,
            timestamp: Date().timeIntervalSince1970
        )
    }

    // MARK: - Mock Training Data

    /// Generate a mock training dataset for the provided gesture definitions
    public static func mockTrainingDataset(name: String = "Mock Dataset", gestures: [GestureDefinition]) -> TrainingDataset {
        var dataset = TrainingDataset(name: name)

        for gesture in gestures {
            let exampleCount = Int.random(in: 5...15)
            for _ in 0..<exampleCount {
                let handfilm = generateMockHandfilm()
                let example = TrainingExample(
                    handfilm: handfilm,
                    gestureId: gesture.id,
                    userId: "mock_user_\(Int.random(in: 1...5))",
                    sessionId: UUID().uuidString
                )
                dataset.addExample(example)
            }
        }

        return dataset
    }

    /// Generate mock model metrics for a given number of gesture classes
    public static func mockModelMetrics(gestureCount: Int = 0) -> ModelMetrics {
        let size = max(gestureCount, 1)
        let confusionMatrix = (0..<size).map { i in
            (0..<size).map { j in
                i == j ? Int.random(in: 80...95) : Int.random(in: 0...10)
            }
        }

        return ModelMetrics(
            accuracy: Float.random(in: 0.85...0.95),
            precision: Float.random(in: 0.82...0.93),
            recall: Float.random(in: 0.80...0.92),
            f1Score: Float.random(in: 0.81...0.93),
            confusionMatrix: confusionMatrix,
            trainingTime: Double.random(in: 30...120),
            validationTime: Double.random(in: 5...15)
        )
    }

    // MARK: - Private Helpers

    private static func generateMockHandfilm() -> HandFilm {
        var handfilm = HandFilm()
        let frameCount = Int.random(in: 10...30)
        let baseTime = Date().timeIntervalSince1970

        for i in 0..<frameCount {
            let handshot = HandShot(
                landmarks: generateGenericLandmarks(),
                timestamp: baseTime + Double(i) * 0.033,
                leftOrRight: Bool.random() ? .left : .right
            )
            handfilm.addFrame(handshot)
        }

        return handfilm
    }

    private static func generateGenericLandmarks() -> [Point3D] {
        (0..<21).map { _ in
            Point3D(
                x: Float.random(in: -0.5...0.5),
                y: Float.random(in: -1.0...0.0),
                z: Float.random(in: 0.0...0.2)
            )
        }
    }
}
