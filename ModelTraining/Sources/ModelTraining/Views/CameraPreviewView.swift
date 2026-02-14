import Cocoa
import AVFoundation

class CameraPreviewView: NSView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var landmarksLayer: CAShapeLayer!
    private var captureSession: AVCaptureSession?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        
        // Layer for drawing hand landmarks
        landmarksLayer = CAShapeLayer()
        landmarksLayer.fillColor = NSColor.systemGreen.withAlphaComponent(0.3).cgColor
        landmarksLayer.strokeColor = NSColor.systemGreen.cgColor
        landmarksLayer.lineWidth = 2.0
        layer?.addSublayer(landmarksLayer)
    }
    
    func startPreview() {
        setupCaptureSession()
    }
    
    func stopPreview() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified),
              let input = try? AVCaptureDeviceInput(device: camera),
              let captureSession = captureSession else {
            print("Failed to setup camera")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Create preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = bounds
        
        if let previewLayer = previewLayer {
            layer?.insertSublayer(previewLayer, at: 0)
        }
        
        captureSession.startRunning()
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
        landmarksLayer.frame = bounds
    }
    
    func updateHandLandmarks(_ landmarks: [Point3D]) {
        guard landmarks.count == 21 else { return } // MediaPipe hand has 21 landmarks
        
        let path = CGMutablePath()
        
        // Convert normalized coordinates to view coordinates
        let points = landmarks.map { landmark in
            CGPoint(x: CGFloat(landmark.x) * bounds.width,
                    y: CGFloat(1.0 - landmark.y) * bounds.height) // Flip Y coordinate
        }
        
        // Draw connections between landmarks (simplified hand skeleton)
        drawHandConnections(path: path, points: points)
        
        // Draw landmark points
        for point in points {
            let circle = CGPath(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6), transform: nil)
            path.addPath(circle)
        }
        
        landmarksLayer.path = path
    }
    
    private func drawHandConnections(path: CGMutablePath, points: [CGPoint]) {
        // Hand connections based on MediaPipe hand model
        let connections: [(Int, Int)] = [
            // Thumb
            (0, 1), (1, 2), (2, 3), (3, 4),
            // Index finger
            (0, 5), (5, 6), (6, 7), (7, 8),
            // Middle finger
            (0, 9), (9, 10), (10, 11), (11, 12),
            // Ring finger
            (0, 13), (13, 14), (14, 15), (15, 16),
            // Pinky
            (0, 17), (17, 18), (18, 19), (19, 20),
            // Palm
            (5, 9), (9, 13), (13, 17)
        ]
        
        for (from, to) in connections {
            path.move(to: points[from])
            path.addLine(to: points[to])
        }
    }
}
