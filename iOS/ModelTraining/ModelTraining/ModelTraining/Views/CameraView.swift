import SwiftUI
import AVFoundation
import GestureModelModule
import HandGestureTypes
import HandsRecognizingModule
import HandGestureRecognizingFramework

struct CameraView: View {
    @EnvironmentObject var gestureRecognizer: GestureRecognizerWrapper
    @EnvironmentObject var appSettings: AppSettings

    @State private var isRecognitionActive = false
    @State private var currentGesture: DetectedGesture?
    @State private var recentGestures: [DetectedGesture] = []
    @State private var handTrackingPoints: [Point3D] = []
    @State private var stats = GestureRecognizingStats()

    @State private var showingPermissionAlert = false
    @State private var cameraPermissionGranted = false
    @State private var showModelNotTrainedBanner = false

    private var isModelTrained: Bool {
        guard let path = appSettings.modelConfig.modelPath else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    var body: some View {
        NavigationView {
            VStack {
                // Model not trained banner
                if showModelNotTrainedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No trained model found. Go to Training to train the model first.")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button {
                            showModelNotTrainedBanner = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Camera Preview Section
                CameraPreviewView(
                    handTrackingPoints: $handTrackingPoints,
                    isActive: $isRecognitionActive
                )
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isRecognitionActive ? Color.green : Color.gray, lineWidth: 2)
                )
                
                // Current Gesture Display
                if let currentGesture = currentGesture {
                    CurrentGestureView(gesture: currentGesture)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Controls
                HStack(spacing: 20) {
                    // Start/Stop Button
                    Button(action: toggleRecognition) {
                        HStack {
                            Image(systemName: isRecognitionActive ? "stop.fill" : "play.fill")
                            Text(isRecognitionActive ? "Stop" : "Start")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecognitionActive ? Color.red : Color.green)
                        .cornerRadius(8)
                    }
                    .disabled(!cameraPermissionGranted)
                    
                    // Stats Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Stats")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                }
                .padding()
                
                // Recent Gestures List
                if !recentGestures.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Gestures")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(recentGestures.reversed().indices, id: \.self) { index in
                                    let gesture = recentGestures.reversed()[index]
                                    RecentGestureRow(gesture: gesture)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Live Recognition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        clearGestures()
                    }
                    .disabled(recentGestures.isEmpty)
                }
            }
        }
        .onAppear {
            checkCameraPermission()
            setupGestureCallbacks()
            appSettings.updateModelConfig()
            showModelNotTrainedBanner = !isModelTrained
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to use gesture recognition.")
        }
    }
    
    // MARK: - Actions
    
    private func toggleRecognition() {
        if isRecognitionActive {
            stopRecognition()
        } else {
            startRecognition()
        }
    }
    
    private func startRecognition() {
        guard isModelTrained else {
            showModelNotTrainedBanner = true
            return
        }
        Task {
            do {
                try await gestureRecognizer.recognizer.start()
                await MainActor.run {
                    isRecognitionActive = true
                }
            } catch {
                await MainActor.run {
                    print("Failed to start recognition: \(error)")
                }
            }
        }
    }
    
    private func stopRecognition() {
        gestureRecognizer.recognizer.stop()
        isRecognitionActive = false
    }
    
    private func clearGestures() {
        recentGestures.removeAll()
        currentGesture = nil
        gestureRecognizer.recognizer.clearHistory()
    }
    
    // MARK: - Setup
    
    private func setupGestureCallbacks() {
        gestureRecognizer.recognizer.gestureDetectionCallback = { gesture in
            DispatchQueue.main.async {
                currentGesture = gesture
                recentGestures.append(gesture)
                
                // Keep only recent gestures
                if recentGestures.count > 50 {
                    recentGestures.removeFirst()
                }
            }
        }
        
        gestureRecognizer.recognizer.handTrackingUpdateCallback = { handshot in
            DispatchQueue.main.async {
                handTrackingPoints = handshot.landmarks
            }
        }
        
        // Update stats periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isRecognitionActive {
                stats = gestureRecognizer.recognizer.getStatistics()
            }
        }
    }
    
    private func checkCameraPermission() {
        Task {
            let permission = await HandsRecognizing.requestCameraPermission()
            await MainActor.run {
                cameraPermissionGranted = permission
                if !permission {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var handTrackingPoints: [Point3D]
    @Binding var isActive: Bool
    
    func makeUIViewController(context: Context) -> CameraPreviewController {
        return CameraPreviewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {
        uiViewController.updateHandTrackingPoints(handTrackingPoints)
        
        if isActive {
            uiViewController.startCamera()
        } else {
            uiViewController.stopCamera()
        }
    }
}

class CameraPreviewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var handTrackingOverlay: HandTrackingOverlayView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }
    
    private func setupOverlay() {
        handTrackingOverlay = HandTrackingOverlayView()
        handTrackingOverlay?.backgroundColor = .clear
        
        if let overlay = handTrackingOverlay {
            view.addSubview(overlay)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    func startCamera() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopCamera() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func updateHandTrackingPoints(_ points: [Point3D]) {
        DispatchQueue.main.async { [weak self] in
            self?.handTrackingOverlay?.updatePoints(points)
        }
    }
}

// MARK: - Hand Tracking Overlay

class HandTrackingOverlayView: UIView {
    private var handPoints: [Point3D] = []
    
    func updatePoints(_ points: [Point3D]) {
        handPoints = points
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !handPoints.isEmpty else { return }
        
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(2.0)
        
        // Draw hand landmarks
        for point in handPoints {
            let x = CGFloat(point.x) * rect.width
            let y = CGFloat(point.y) * rect.height
            let adjustedPoint = CGPoint(x: x, y: y)
            
            context.addEllipse(in: CGRect(
                x: adjustedPoint.x - 3,
                y: adjustedPoint.y - 3,
                width: 6,
                height: 6
            ))
        }
        
        context.strokePath()
        
        // Draw hand skeleton connections (simplified)
        drawHandConnections(context: context, rect: rect)
    }
    
    private func drawHandConnections(context: CGContext, rect: CGRect) {
        guard handPoints.count >= 21 else { return }
        
        // Define hand landmark connections
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
            (0, 17), (17, 18), (18, 19), (19, 20)
        ]
        
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(1.0)
        
        for (start, end) in connections {
            if start < handPoints.count && end < handPoints.count {
                let startPoint = handPoints[start]
                let endPoint = handPoints[end]
                
                let startCG = CGPoint(
                    x: CGFloat(startPoint.x) * rect.width,
                    y: CGFloat(startPoint.y) * rect.height
                )
                let endCG = CGPoint(
                    x: CGFloat(endPoint.x) * rect.width,
                    y: CGFloat(endPoint.y) * rect.height
                )
                
                context.move(to: startCG)
                context.addLine(to: endCG)
            }
        }
        
        context.strokePath()
    }
}

// MARK: - Current Gesture View

struct CurrentGestureView: View {
    let gesture: DetectedGesture
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.blue)
                
                Text(gesture.prediction.gestureName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(gesture.prediction.confidence * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Text("Latency: \(String(format: "%.1f", gesture.processingLatency * 1000))ms")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Recent Gesture Row

struct RecentGestureRow: View {
    let gesture: DetectedGesture
    
    var body: some View {
        HStack {
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
            
            Text(gesture.prediction.gestureName)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Text("\(Int(gesture.prediction.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(timeAgo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
    
    private var confidenceColor: Color {
        if gesture.prediction.confidence > 0.8 {
            return .green
        } else if gesture.prediction.confidence > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var timeAgo: String {
        let interval = Date().timeIntervalSince1970 - gesture.detectionTimestamp
        if interval < 60 {
            return "\(Int(interval))s"
        } else {
            return "\(Int(interval / 60))m"
        }
    }
}

// MARK: - Preview

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
            .environmentObject(GestureRecognizerWrapper(recognizer: HandGestureRecognizing()))
            .environmentObject(AppSettings())
    }
}
