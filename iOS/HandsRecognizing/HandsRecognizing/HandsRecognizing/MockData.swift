import Foundation
import HandGestureTypes

/// Mock data generator for HandsRecognizing framework
public enum MockData {
    
    // MARK: - Hand Landmark Indices
    
    /// MediaPipe hand landmark indices
    private enum LandmarkIndex: Int, CaseIterable {
        case wrist = 0
        case thumbCMC = 1, thumbMCP = 2, thumbIP = 3, thumbTip = 4
        case indexMCP = 5, indexPIP = 6, indexDIP = 7, indexTip = 8
        case middleMCP = 9, middlePIP = 10, middleDIP = 11, middleTip = 12
        case ringMCP = 13, ringPIP = 14, ringDIP = 15, ringTip = 16
        case pinkyMCP = 17, pinkyPIP = 18, pinkyDIP = 19, pinkyTip = 20
    }
    
    // MARK: - Mock Landmark Generation
    
    /// Generates realistic hand landmarks for a relaxed open hand
    public static func openHandLandmarks(handedness: LeftOrRight = .right) -> [Point3D] {
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
        
        return baseCoordinates.map { coords in
            let (x, y, z) = coords
            // Mirror for left hand
            let adjustedX = handedness == .left ? -x : x
            return Point3D(x: adjustedX, y: y, z: z)
        }
    }
    
    /// Generates hand landmarks for a closed fist
    public static func fistLandmarks(handedness: LeftOrRight = .right) -> [Point3D] {
        let baseCoordinates: [(Float, Float, Float)] = [
            // Wrist
            (0.0, 0.0, 0.0),
            // Thumb (wrapped around fingers)
            (-0.05, -0.1, 0.05), (-0.08, -0.15, 0.08), (-0.1, -0.2, 0.1), (-0.12, -0.25, 0.12),
            // Index finger (curled)
            (0.05, -0.25, 0.1), (0.08, -0.3, 0.15), (0.1, -0.28, 0.18), (0.12, -0.25, 0.2),
            // Middle finger (curled)
            (0.0, -0.3, 0.1), (0.02, -0.35, 0.15), (0.05, -0.33, 0.18), (0.08, -0.3, 0.2),
            // Ring finger (curled)
            (-0.05, -0.25, 0.1), (-0.03, -0.3, 0.15), (0.0, -0.28, 0.18), (0.03, -0.25, 0.2),
            // Pinky (curled)
            (-0.1, -0.2, 0.08), (-0.08, -0.25, 0.12), (-0.05, -0.23, 0.15), (-0.02, -0.2, 0.17)
        ]
        
        return baseCoordinates.map { coords in
            let (x, y, z) = coords
            let adjustedX = handedness == .left ? -x : x
            return Point3D(x: adjustedX, y: y, z: z)
        }
    }
    
    /// Generates hand landmarks for pointing gesture (index finger extended)
    public static func pointingLandmarks(handedness: LeftOrRight = .right) -> [Point3D] {
        let baseCoordinates: [(Float, Float, Float)] = [
            // Wrist
            (0.0, 0.0, 0.0),
            // Thumb (partially closed)
            (-0.08, -0.12, 0.04), (-0.12, -0.18, 0.06), (-0.15, -0.22, 0.08), (-0.17, -0.25, 0.1),
            // Index finger (extended)
            (0.05, -0.4, 0.0), (0.05, -0.6, 0.0), (0.05, -0.75, 0.0), (0.05, -0.9, 0.0),
            // Middle finger (curled)
            (0.0, -0.25, 0.08), (0.02, -0.3, 0.12), (0.05, -0.28, 0.15), (0.08, -0.25, 0.17),
            // Ring finger (curled)
            (-0.05, -0.22, 0.08), (-0.03, -0.27, 0.12), (0.0, -0.25, 0.15), (0.03, -0.22, 0.17),
            // Pinky (curled)
            (-0.1, -0.18, 0.06), (-0.08, -0.22, 0.1), (-0.05, -0.2, 0.13), (-0.02, -0.17, 0.15)
        ]
        
        return baseCoordinates.map { coords in
            let (x, y, z) = coords
            let adjustedX = handedness == .left ? -x : x
            return Point3D(x: adjustedX, y: y, z: z)
        }
    }
    
    /// Generates hand landmarks for peace/victory sign (index and middle fingers extended)
    public static func peaceLandmarks(handedness: LeftOrRight = .right) -> [Point3D] {
        let baseCoordinates: [(Float, Float, Float)] = [
            // Wrist
            (0.0, 0.0, 0.0),
            // Thumb (closed)
            (-0.08, -0.12, 0.04), (-0.12, -0.18, 0.06), (-0.15, -0.22, 0.08), (-0.17, -0.25, 0.1),
            // Index finger (extended, spread)
            (0.08, -0.4, 0.0), (0.1, -0.6, 0.0), (0.12, -0.75, 0.0), (0.15, -0.9, 0.0),
            // Middle finger (extended, spread)
            (-0.02, -0.45, 0.0), (-0.05, -0.65, 0.0), (-0.08, -0.8, 0.0), (-0.12, -0.95, 0.0),
            // Ring finger (curled)
            (-0.08, -0.22, 0.08), (-0.06, -0.27, 0.12), (-0.03, -0.25, 0.15), (0.0, -0.22, 0.17),
            // Pinky (curled)
            (-0.12, -0.18, 0.06), (-0.1, -0.22, 0.1), (-0.07, -0.2, 0.13), (-0.04, -0.17, 0.15)
        ]
        
        return baseCoordinates.map { coords in
            let (x, y, z) = coords
            let adjustedX = handedness == .left ? -x : x
            return Point3D(x: adjustedX, y: y, z: z)
        }
    }
    
    // MARK: - Mock Gesture Sequences
    
    /// Creates a mock handfilm showing a wave gesture
    public static func waveGesture() -> HandFilm {
        var handfilm = HandFilm()
        let baseTime = Date().timeIntervalSince1970
        
        // Wave motion: open hand moving side to side
        for i in 0..<30 {
            let t = Float(i) / 30.0
            let waveOffset = sin(t * .pi * 4) * 0.1 // Side to side motion
            
            let landmarks = openHandLandmarks().map { point in
                Point3D(x: point.x + waveOffset, y: point.y, z: point.z)
            }
            
            let handshot = HandShot(
                landmarks: landmarks,
                timestamp: baseTime + Double(i) * 0.033, // ~30 FPS
                leftOrRight: .right
            )
            handfilm.addFrame(handshot)
        }
        
        return handfilm
    }
    
    /// Creates a mock handfilm showing a grab gesture
    public static func grabGesture() -> HandFilm {
        var handfilm = HandFilm()
        let baseTime = Date().timeIntervalSince1970
        
        // Transition from open hand to fist
        for i in 0..<20 {
            let t = Float(i) / 19.0
            let openHand = openHandLandmarks()
            let closedHand = fistLandmarks()
            
            // Interpolate between open and closed
            let landmarks = zip(openHand, closedHand).map { open, closed in
                Point3D(
                    x: open.x + (closed.x - open.x) * t,
                    y: open.y + (closed.y - open.y) * t,
                    z: open.z + (closed.z - open.z) * t
                )
            }
            
            let handshot = HandShot(
                landmarks: landmarks,
                timestamp: baseTime + Double(i) * 0.05,
                leftOrRight: .right
            )
            handfilm.addFrame(handshot)
        }
        
        return handfilm
    }
    
    /// Creates a random gesture sequence
    public static func randomGesture() -> HandFilm {
        let gestures = [waveGesture, grabGesture]
        return gestures.randomElement()!()
    }
}
