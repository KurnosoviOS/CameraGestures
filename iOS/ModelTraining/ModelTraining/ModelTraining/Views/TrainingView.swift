import SwiftUI
import HandGestureTypes
import GestureModelModule
import HandsRecognizingModule
import HandGestureRecognizingFramework

struct TrainingView: View {
    @EnvironmentObject var gestureRecognizer: GestureRecognizerWrapper
    @EnvironmentObject var trainingDataManager: TrainingDataManager
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var selectedGestureType: GestureType = .openHand
    @State private var isCollecting = false
    @State private var collectionProgress: Double = 0.0
    @State private var targetSamples = 20
    @State private var currentSamples = 0
    @State private var showingNewDatasetAlert = false
    @State private var newDatasetName = ""
    @State private var showingTrainingAlert = false
    
    private let gestureTypes = GestureType.allCases
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Dataset Info Section
                datasetInfoSection
                
                // Gesture Selection Section
                gestureSelectionSection
                
                // Collection Progress Section
                if isCollecting {
                    collectionProgressSection
                }
                
                // Collection Controls
                collectionControlsSection
                
                // Training Data Summary
                trainingDataSummarySection
                
                // Training Controls
                trainingControlsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Training Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Dataset") {
                        showingNewDatasetAlert = true
                    }
                }
            }
        }
        .onAppear {
            setupTrainingCallbacks()
        }
        .alert("New Dataset", isPresented: $showingNewDatasetAlert) {
            TextField("Dataset Name", text: $newDatasetName)
            Button("Create") {
                createNewDataset()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the new training dataset")
        }
        .alert("Training Complete", isPresented: $showingTrainingAlert) {
            Button("OK") { }
        } message: {
            Text("Model training completed successfully!")
        }
    }
    
    // MARK: - UI Sections
    
    private var datasetInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Dataset")
                .font(.headline)
            
            if let dataset = trainingDataManager.currentDataset {
                HStack {
                    VStack(alignment: .leading) {
                        Text(dataset.name)
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("\(dataset.examples.count) examples")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        trainingDataManager.saveDataset()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("No dataset selected")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var gestureSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Gesture Type")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gestureTypes, id: \.self) { gestureType in
                        GestureSelectionCard(
                            gestureType: gestureType,
                            isSelected: gestureType == selectedGestureType,
                            sampleCount: getSampleCount(for: gestureType)
                        ) {
                            selectedGestureType = gestureType
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var collectionProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Collecting: \(selectedGestureType.displayName)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(currentSamples)/\(targetSamples)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: collectionProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 2.0)
            
            Text("Perform the gesture in front of the camera")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var collectionControlsSection: some View {
        VStack(spacing: 12) {
            if !isCollecting {
                // Start Collection
                Button(action: startCollection) {
                    HStack {
                        Image(systemName: "record.circle")
                        Text("Start Collecting")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .disabled(trainingDataManager.currentDataset == nil)
                
                // Target Samples Stepper
                HStack {
                    Text("Target Samples:")
                    
                    Spacer()
                    
                    Stepper(value: $targetSamples, in: 5...50, step: 5) {
                        Text("\(targetSamples)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
            } else {
                // Stop Collection
                Button(action: stopCollection) {
                    HStack {
                        Image(systemName: "stop.circle")
                        Text("Stop Collecting")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var trainingDataSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Training Data Summary")
                .font(.headline)
            
            if let dataset = trainingDataManager.currentDataset, !dataset.examples.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(gestureTypes, id: \.self) { gestureType in
                        let count = getSampleCount(for: gestureType)
                        
                        HStack {
                            Text(gestureType.displayName)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(count >= 10 ? .green : .orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            } else {
                Text("No training data collected yet")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var trainingControlsSection: some View {
        VStack(spacing: 12) {
            Button(action: startTraining) {
                HStack {
                    Image(systemName: "brain")
                    Text("Train Model")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(canStartTraining ? Color.blue : Color.gray)
                .cornerRadius(8)
            }
            .disabled(!canStartTraining)
            
            if let dataset = trainingDataManager.currentDataset {
                Text("Total examples: \(dataset.examples.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canStartTraining: Bool {
        guard let dataset = trainingDataManager.currentDataset else { return false }
        
        // Check if we have at least 5 examples for each gesture type
        let gestureCount = dataset.gestureCount
        return gestureTypes.allSatisfy { type in
            (gestureCount[type] ?? 0) >= 5
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSampleCount(for gestureType: GestureType) -> Int {
        return trainingDataManager.currentDataset?.gestureCount[gestureType] ?? 0
    }
    
    private func createNewDataset() {
        guard !newDatasetName.isEmpty else { return }
        
        trainingDataManager.createNewDataset(name: newDatasetName)
        newDatasetName = ""
    }
    
    private func startCollection() {
        isCollecting = true
        currentSamples = 0
        collectionProgress = 0.0
        
        trainingDataManager.startDataCollection(for: selectedGestureType)
        
        // Start gesture recognition if not already running
        if !gestureRecognizer.recognizer.isActive {
            Task {
                try await gestureRecognizer.recognizer.start()
            }
        }
    }
    
    private func stopCollection() {
        isCollecting = false
        trainingDataManager.stopDataCollection()
        
        // Provide haptic feedback
        if appSettings.enableHapticFeedback {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    private func startTraining() {
        guard let dataset = trainingDataManager.currentDataset else { return }
        
        Task {
            do {
                // Create a gesture model for training
                let gestureModel = GestureModel(config: appSettings.modelConfig)
                
                // Start training (this is a mock implementation)
                let metrics = try await gestureModel.train(dataset: dataset)
                
                await MainActor.run {
                    print("Training completed with accuracy: \(metrics.accuracy)")
                    showingTrainingAlert = true
                }
                
            } catch {
                print("Training failed: \(error)")
            }
        }
    }
    
    private func setupTrainingCallbacks() {
        // This would be called when gesture detection occurs during training
        gestureRecognizer.recognizer.gestureDetectionCallback = { detectedGesture in
            DispatchQueue.main.async {
                if isCollecting && detectedGesture.prediction.confidence > 0.6 {
                    handleTrainingGesture(detectedGesture)
                }
            }
        }
    }
    
    private func handleTrainingGesture(_ gesture: DetectedGesture) {
        // Add to training data if collecting
        if trainingDataManager.isCollecting,
           trainingDataManager.currentGestureType == selectedGestureType {
            
            let example = TrainingExample(
                handfilm: gesture.handfilm,
                gestureType: selectedGestureType,
                userId: "current_user",
                sessionId: UUID().uuidString
            )
            
            trainingDataManager.addTrainingExample(example)
            
            currentSamples += 1
            collectionProgress = Double(currentSamples) / Double(targetSamples)
            
            // Auto-stop when target reached
            if currentSamples >= targetSamples {
                stopCollection()
            }
            
            // Provide haptic feedback
            if appSettings.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
}

// MARK: - Gesture Selection Card

struct GestureSelectionCard: View {
    let gestureType: GestureType
    let isSelected: Bool
    let sampleCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Gesture Icon (using SF Symbols as placeholders)
                Image(systemName: gestureIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(gestureType.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Sample count badge
                if sampleCount > 0 {
                    Text("\(sampleCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .blue : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white : .blue)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .frame(width: 100, height: 80)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var gestureIcon: String {
        switch gestureType {
        case .openHand:
            return "hand.raised"
        case .closedFist:
            return "hand.raised.slash"
        case .pointing:
            return "hand.point.right"
        case .peace:
            return "hand.peace"
        case .wave:
            return "hand.wave"
        case .grab:
            return "hand.raised.fingers.spread"
        case .swipeLeft:
            return "arrow.left"
        case .swipeRight:
            return "arrow.right"
        case .thumbsUp:
            return "hand.thumbsup"
        case .thumbsDown:
            return "hand.thumbsdown"
        }
    }
}

// MARK: - Preview

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView()
            .environmentObject(GestureRecognizerWrapper(recognizer:  HandGestureRecognizing()))
            .environmentObject(TrainingDataManager())
            .environmentObject(AppSettings())
    }
}
