import Foundation
import HandGestureTypes

/// Converts a HandFilm into a fixed-length feature matrix for TensorFlow Lite inference.
///
/// Output shape: 60 frames × 126 features/frame
///   [0..62]  — 21 landmark (x, y, z) triplets normalized relative to wrist (landmark 0)
///   [63..125] — frame-to-frame velocity of those same 63 coordinates (zero for first frame)
enum FeaturePreprocessor {

    static let frameCount = 60
    static let landmarkCount = 21
    static let coordsPerFrame = landmarkCount * 3       // 63
    static let featuresPerFrame = coordsPerFrame * 2    // 126

    // MARK: - Public API

    /// Convert a HandFilm to a [frameCount × featuresPerFrame] Double matrix.
    /// - Returns: Flat row-major array of length frameCount × featuresPerFrame.
    static func featureMatrix(from handfilm: HandFilm) -> [Double] {
        let normalizedFrames = buildNormalizedFrames(from: handfilm)
        let velocityFrames = buildVelocityFrames(from: normalizedFrames)

        var result = [Double]()
        result.reserveCapacity(frameCount * featuresPerFrame)

        for i in 0..<frameCount {
            result.append(contentsOf: normalizedFrames[i])
            result.append(contentsOf: velocityFrames[i])
        }
        return result
    }

    /// Convenience: returns the matrix as a nested array (rows = frames, cols = features).
    static func featureRows(from handfilm: HandFilm) -> [[Double]] {
        let flat = featureMatrix(from: handfilm)
        return (0..<frameCount).map { i in
            Array(flat[(i * featuresPerFrame)..<((i + 1) * featuresPerFrame)])
        }
    }

    // MARK: - Private Helpers

    /// Extract and normalize landmark coords for each frame, pad/trim to frameCount.
    private static func buildNormalizedFrames(from handfilm: HandFilm) -> [[Double]] {
        let frames = handfilm.frames
        var normalized = [[Double]]()
        normalized.reserveCapacity(frameCount)

        // Use last `frameCount` frames if the film is longer; pad with zeros if shorter.
        let startIndex = max(0, frames.count - frameCount)

        for i in startIndex..<frames.count {
            normalized.append(normalizeFrame(frames[i]))
        }

        let zeroFrame = [Double](repeating: 0.0, count: coordsPerFrame)
        while normalized.count < frameCount {
            normalized.append(zeroFrame)
        }

        return normalized
    }

    /// Normalize a single HandShot's 21 landmarks relative to wrist (landmark 0).
    private static func normalizeFrame(_ handshot: HandShot) -> [Double] {
        let landmarks = handshot.landmarks
        guard landmarks.count == landmarkCount else {
            return [Double](repeating: 0.0, count: coordsPerFrame)
        }

        let wrist = landmarks[0]
        var coords = [Double]()
        coords.reserveCapacity(coordsPerFrame)

        for lm in landmarks {
            coords.append(Double(lm.x - wrist.x))
            coords.append(Double(lm.y - wrist.y))
            coords.append(Double(lm.z - wrist.z))
        }
        return coords
    }

    /// Compute frame-to-frame velocity; first frame velocity is all zeros.
    private static func buildVelocityFrames(from normalizedFrames: [[Double]]) -> [[Double]] {
        let zeroFrame = [Double](repeating: 0.0, count: coordsPerFrame)
        var velocity = [zeroFrame]

        for i in 1..<normalizedFrames.count {
            var delta = [Double](repeating: 0.0, count: coordsPerFrame)
            for j in 0..<coordsPerFrame {
                delta[j] = normalizedFrames[i][j] - normalizedFrames[i - 1][j]
            }
            velocity.append(delta)
        }
        return velocity
    }
}
