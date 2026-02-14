import SwiftUI
import HandGestureTypes
import HandGestureRecognizingFramework

struct ContentView: View {
    @EnvironmentObject var gestureRecognizer: GestureRecognizerWrapper
    @EnvironmentObject var trainingDataManager: TrainingDataManager
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera and Live Recognition
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(0)
            
            // Training Data Collection
            TrainingView()
                .tabItem {
                    Image(systemName: "hand.raised.fill")
                    Text("Training")
                }
                .tag(1)
            
            // Gesture Management
            GestureListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Gestures")
                }
                .tag(2)
            
            // Settings
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            setupGestureRecognizer()
        }
        .alert("System Alert", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupGestureRecognizer() {
        // Configure gesture recognition callbacks
        gestureRecognizer.recognizer.gestureDetectionCallback = { detectedGesture in
            DispatchQueue.main.async {
                handleGestureDetection(detectedGesture)
            }
        }
        
        gestureRecognizer.recognizer.statusChangeCallback = { status in
            DispatchQueue.main.async {
                handleStatusChange(status)
            }
        }
        
        // Initialize with current settings
        let config = HandGestureRecognizingConfig(
            handsRecognizingConfig: appSettings.cameraConfig,
            gestureModelConfig: appSettings.modelConfig,
            enableRealTimeProcessing: true,
            gestureBufferSize: 10,
            confidenceThreshold: appSettings.confidenceThreshold
        )
        
        Task {
            do {
                try await gestureRecognizer.recognizer.initialize(config: config)
            } catch {
                await MainActor.run {
                    showAlert("Initialization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleGestureDetection(_ gesture: DetectedGesture) {
        // Handle gesture detection based on current mode
        if trainingDataManager.isCollecting,
           let gestureType = trainingDataManager.currentGestureType {
            
            // Add to training data
            let example = TrainingExample(
                handfilm: gesture.handfilm,
                gestureType: gestureType,
                userId: "current_user",
                sessionId: UUID().uuidString
            )
            
            trainingDataManager.addTrainingExample(example)
            
            // Provide haptic feedback
            if appSettings.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func handleStatusChange(_ status: GestureRecognizingStatus) {
        switch status {
        case .error(let error):
            showAlert("Error: \(error)")
        case .running:
            print("Gesture recognition started")
        case .idle:
            print("Gesture recognition stopped")
        default:
            break
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GestureRecognizerWrapper(recognizer: HandGestureRecognizing()))
            .environmentObject(TrainingDataManager())
            .environmentObject(AppSettings())
    }
}
