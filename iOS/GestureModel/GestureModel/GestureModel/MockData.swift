import Foundation
import HandGestureTypes

/// Mock data generator for GestureModel framework
public enum MockData {
    
    // MARK: - Mock Predictions
    
    /// Generate mock gesture predictions with realistic confidence scores
    public static func mockPredictions() -> [GesturePrediction] {
        let gestures: [(GestureType, Float)] = [
            (.openHand, 0.85),
            (.pointing, 0.72),
            (.peace, 0.68),
            (.wave, 0.45),
            (.closedFist, 0.23)
        ]
        
        return gestures.map { gestureType, confidence in
            GesturePrediction(
                gestureId: gestureType.rawValue,
                gestureName: gestureType.displayName,
                confidence: confidence + Float.random(in: -0.1...0.1), // Add some variance
                timestamp: Date().timeIntervalSince1970
            )
        }
    }
    
    /// Generate a single high-confidence prediction
    public static func highConfidencePrediction() -> GesturePrediction {
        let gestureType = GestureType.allCases.randomElement()!
        return GesturePrediction(
            gestureId: gestureType.rawValue,
            gestureName: gestureType.displayName,
            confidence: Float.random(in: 0.85...0.95),
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    /// Generate a low-confidence prediction
    public static func lowConfidencePrediction() -> GesturePrediction {
        let gestureType = GestureType.allCases.randomElement()!
        return GesturePrediction(
            gestureId: gestureType.rawValue,
            gestureName: gestureType.displayName,
            confidence: Float.random(in: 0.3...0.6),
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    // MARK: - Mock Training Data
    
    /// Generate a mock training dataset
    public static func mockTrainingDataset(name: String = "Mock Dataset") -> TrainingDataset {
        var dataset = TrainingDataset(name: name)
        
        // Generate examples for each gesture type
        for gestureType in GestureType.allCases {
            let exampleCount = Int.random(in: 5...15)
            
            for _ in 0..<exampleCount {
                let handfilm = generateMockHandfilm(for: gestureType)
                let example = TrainingExample(
                    handfilm: handfilm,
                    gestureType: gestureType,
                    userId: "mock_user_\(Int.random(in: 1...5))",
                    sessionId: UUID().uuidString
                )
                dataset.addExample(example)
            }
        }
        
        return dataset
    }
    
    /// Generate mock model metrics
    public static func mockModelMetrics() -> ModelMetrics {
        let gestureCount = GestureType.allCases.count
        let confusionMatrix = (0..<gestureCount).map { i in
            (0..<gestureCount).map { j in
                if i == j {
                    return Int.random(in: 80...95) // High diagonal values
                } else {
                    return Int.random(in: 0...10)  // Low off-diagonal values
                }
            }
        }
        
        return ModelMetrics(
            accuracy: Float.random(in: 0.85...0.95),
            precision: Float.random(in: 0.82...0.93),
            recall: Float.random(in: 0.80...0.92),
            f1Score: Float.random(in: 0.81...0.93),
            confusionMatrix: confusionMatrix,
            trainingTime: Double.random(in: 30...120), // 30 seconds to 2 minutes
            validationTime: Double.random(in: 5...15)   // 5 to 15 seconds
        )
    }
    
    // MARK: - Private Helpers
    
    private static func generateMockHandfilm(for gestureType: GestureType) -> HandFilm {
        var handfilm = HandFilm()
        let frameCount = Int.random(in: 10...30)
        let baseTime = Date().timeIntervalSince1970
        
        for i in 0..<frameCount {
            let landmarks = generateMockLandmarks(for: gestureType, frame: i, totalFrames: frameCount)
            let handshot = HandShot(
                landmarks: landmarks,
                timestamp: baseTime + Double(i) * 0.033, // ~30 FPS
                leftOrRight: Bool.random() ? .left : .right
            )
            handfilm.addFrame(handshot)
        }
        
        return handfilm
    }
    
    private static func generateMockLandmarks(for gestureType: GestureType, frame: Int, totalFrames: Int) -> [Point3D] {
        // Generate 21 landmarks (MediaPipe hand model)
        let progress = Float(frame) / Float(totalFrames)
        
        switch gestureType {
        case .openHand:
            return generateOpenHandLandmarks()
            
        case .closedFist:
            return generateClosedFistLandmarks()
            
        case .pointing:
            return generatePointingLandmarks()
            
        case .peace:
            return generatePeaceLandmarks()
            
        case .wave:
            return generateWaveLandmarks(progress: progress)
            
        case .grab:
            return generateGrabLandmarks(progress: progress)
            
        case .swipeLeft, .swipeRight:
            let direction: Float = gestureType == .swipeLeft ? -1.0 : 1.0
            return generateSwipeLandmarks(progress: progress, direction: direction)
            
        case .thumbsUp:
            return generateThumbsUpLandmarks()
            
        case .thumbsDown:
            return generateThumbsDownLandmarks()
        }
    }
    
    private static func generateOpenHandLandmarks() -> [Point3D] {
        let baseCoordinates: [(Float, Float, Float)] = [
            // Wrist
            (0.0, 0.0, 0.0),
            // Thumb
            (-0.1, -0.15, 0.02), (-0.15, -0.25, 0.05), (-0.18, -0.35, 0.08), (-0.2, -0.45, 0.1),
            // Index finger
            (0.05, -0.4, 0.0), (0.05, -0.6, 0.0), (0.05, -0.75, 0.0), (0.05, -0.9, 0.0),
            // Middle finger
            (0.0, -0.45, 0.0), (0.0, -0.65, 0.0), (0.0, -0.8, 0.0), (0.0, -0.95, 0.0),
            // Ring finger
            (-0.05, -0.4, 0.0), (-0.05, -0.6, 0.0), (-0.05, -0.75, 0.0), (-0.05, -0.85, 0.0),
            // Pinky
            (-0.1, -0.35, 0.0), (-0.1, -0.5, 0.0), (-0.1, -0.65, 0.0), (-0.1, -0.75, 0.0)
        ]
        
        return baseCoordinates.map { Point3D(x: $0.0, y: $0.1, z: $0.2) }
    }
    
    private static func generateClosedFistLandmarks() -> [Point3D] {
        let baseCoordinates: [(Float, Float, Float)] = [
            // Wrist
            (0.0, 0.0, 0.0),
            // Thumb (wrapped)
            (-0.05, -0.1, 0.05), (-0.08, -0.15, 0.08), (-0.1, -0.2, 0.1), (-0.12, -0.25, 0.12),
            // Fingers (all curled)
            (0.05, -0.25, 0.1), (0.08, -0.3, 0.15), (0.1, -0.28, 0.18), (0.12, -0.25, 0.2),
            (0.0, -0.3, 0.1), (0.02, -0.35, 0.15), (0.05, -0.33, 0.18), (0.08, -0.3, 0.2),
            (-0.05, -0.25, 0.1), (-0.03, -0.3, 0.15), (0.0, -0.28, 0.18), (0.03, -0.25, 0.2),
            (-0.1, -0.2, 0.08), (-0.08, -0.25, 0.12), (-0.05, -0.23, 0.15), (-0.02, -0.2, 0.17)
        ]
        
        return baseCoordinates.map { Point3D(x: $0.0, y: $0.1, z: $0.2) }
    }
    
    private static func generatePointingLandmarks() -> [Point3D] {
        // Index finger extended, others curled
        return generateOpenHandLandmarks() // Simplified for now
    }
    
    private static func generatePeaceLandmarks() -> [Point3D] {
        // Index and middle fingers extended
        return generateOpenHandLandmarks() // Simplified for now
    }
    
    private static func generateWaveLandmarks(progress: Float) -> [Point3D] {
        let waveOffset = sin(progress * .pi * 4) * 0.1
        return generateOpenHandLandmarks().map { point in
            Point3D(x: point.x + waveOffset, y: point.y, z: point.z)
        }
    }
    
    private static func generateGrabLandmarks(progress: Float) -> [Point3D] {
        let openHand = generateOpenHandLandmarks()
        let closedHand = generateClosedFistLandmarks()
        
        return zip(openHand, closedHand).map { open, closed in
            Point3D(
                x: open.x + (closed.x - open.x) * progress,
                y: open.y + (closed.y - open.y) * progress,
                z: open.z + (closed.z - open.z) * progress
            )
        }
    }
    
    private static func generateSwipeLandmarks(progress: Float, direction: Float) -> [Point3D] {
        let swipeOffset = progress * direction * 0.3
        return generateOpenHandLandmarks().map { point in
            Point3D(x: point.x + swipeOffset, y: point.y, z: point.z)
        }
    }
    
    private static func generateThumbsUpLandmarks() -> [Point3D] {
        // Thumb extended up, fingers curled
        return generateClosedFistLandmarks() // Simplified for now
    }
    
    private static func generateThumbsDownLandmarks() -> [Point3D] {
        // Thumb extended down, fingers curled
        return generateClosedFistLandmarks() // Simplified for now
    }
}
