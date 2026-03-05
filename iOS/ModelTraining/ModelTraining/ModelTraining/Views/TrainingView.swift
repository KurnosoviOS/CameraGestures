import SwiftUI
import HandGestureTypes
import GestureModelModule
import HandsRecognizingModule
import HandGestureRecognizingFramework

struct TrainingView: View {
    @EnvironmentObject var gestureRecognizer: GestureRecognizerWrapper
    @EnvironmentObject var trainingDataManager: TrainingDataManager
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var gestureRegistry: GestureRegistry

    @State private var selectedGesture: GestureDefinition?
    @State private var isCollecting = false
    @State private var collectionProgress: Double = 0.0
    @State private var targetSamples = 20
    @State private var currentSamples = 0
    @State private var showingNewDatasetAlert = false
    @State private var newDatasetName = ""
    @State private var showingAddGestureSheet = false
    @State private var showingMetricsSheet = false
    @State private var completedMetrics: ModelMetrics?
    @State private var trainingErrorMessage: String?
    @State private var showingTrainingError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    datasetInfoSection
                    gestureSelectionSection

                    if isCollecting {
                        collectionProgressSection
                    }

                    collectionControlsSection
                    trainingDataSummarySection
                    trainingControlsSection
                }
                .padding()
            }
            .navigationTitle("Training Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAddGestureSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Dataset") {
                        showingNewDatasetAlert = true
                    }
                }
            }
        }
        .onAppear {
            if selectedGesture == nil {
                selectedGesture = gestureRegistry.gestures.first
            }
            setupTrainingCallbacks()
        }
        .onChange(of: gestureRegistry.gestures) { gestures in
            if let current = selectedGesture, !gestures.contains(current) {
                selectedGesture = gestures.first
            } else if selectedGesture == nil {
                selectedGesture = gestures.first
            }
        }
        .sheet(isPresented: $showingAddGestureSheet) {
            AddGestureSheet()
                .environmentObject(gestureRegistry)
        }
        .sheet(isPresented: $showingMetricsSheet) {
            if let metrics = completedMetrics {
                TrainingMetricsSheet(
                    metrics: metrics,
                    gestureIds: gestureRegistry.gestures.map { $0.id }
                )
            }
        }
        .alert("New Dataset", isPresented: $showingNewDatasetAlert) {
            TextField("Dataset Name", text: $newDatasetName)
            Button("Create") { createNewDataset() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the new training dataset")
        }
        .alert("Training Failed", isPresented: $showingTrainingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(trainingErrorMessage ?? "An unknown error occurred.")
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
            HStack {
                Text("Select Gesture")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddGestureSheet = true
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption)
                }
            }

            if gestureRegistry.gestures.isEmpty {
                Text("No gestures defined yet. Tap + to add one.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(gestureRegistry.gestures) { gesture in
                            GestureSelectionCard(
                                gesture: gesture,
                                isSelected: gesture == selectedGesture,
                                sampleCount: getSampleCount(for: gesture)
                            ) {
                                selectedGesture = gesture
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var collectionProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Collecting: \(selectedGesture?.name ?? "")")
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
                .disabled(trainingDataManager.currentDataset == nil || selectedGesture == nil)

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
                    ForEach(gestureRegistry.gestures) { gesture in
                        let count = getSampleCount(for: gesture)

                        HStack {
                            Text(gesture.name)
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
            switch trainingDataManager.trainingState {
            case .idle:
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

            case .training:
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)

                    Text("Training model…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("This may take a few minutes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)

            case .done(let metrics):
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Model trained")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                        Text(String(format: "%.1f%%", metrics.accuracy * 100))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    HStack(spacing: 12) {
                        Button("View Metrics") {
                            completedMetrics = metrics
                            showingMetricsSheet = true
                        }
                        .buttonStyle(.bordered)

                        Button(action: startTraining) {
                            Label("Retrain", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canStartTraining)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)

            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Training failed")
                            .font(.headline)
                            .foregroundColor(.red)
                    }

                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: startTraining) {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!canStartTraining)
                }
                .padding()
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }

            if let dataset = trainingDataManager.currentDataset {
                Text("Total examples: \(dataset.examples.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    private var canStartTraining: Bool {
        guard let dataset = trainingDataManager.currentDataset,
              !gestureRegistry.gestures.isEmpty else { return false }
        let gestureCount = dataset.gestureCount
        return gestureRegistry.gestures.allSatisfy { gesture in
            (gestureCount[gesture.id] ?? 0) >= 5
        }
    }

    // MARK: - Helper Methods

    private func getSampleCount(for gesture: GestureDefinition) -> Int {
        return trainingDataManager.currentDataset?.gestureCount[gesture.id] ?? 0
    }

    private func createNewDataset() {
        guard !newDatasetName.isEmpty else { return }
        trainingDataManager.createNewDataset(name: newDatasetName)
        newDatasetName = ""
    }

    private func startCollection() {
        guard let gesture = selectedGesture else { return }
        isCollecting = true
        currentSamples = 0
        collectionProgress = 0.0

        trainingDataManager.startDataCollection(for: gesture)

        if !gestureRecognizer.recognizer.isActive {
            Task {
                try await gestureRecognizer.recognizer.start()
            }
        }
    }

    private func stopCollection() {
        isCollecting = false
        trainingDataManager.stopDataCollection()

        if appSettings.enableHapticFeedback {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func startTraining() {
        guard let dataset = trainingDataManager.currentDataset else { return }

        trainingDataManager.trainingState = .training

        let modelConfig = GestureModelConfig(
            modelPath: nil,
            backendType: .tensorFlow,
            predictionThreshold: appSettings.confidenceThreshold,
            maxPredictions: 5
        )

        Task {
            do {
                let gestureModel = GestureModel(config: modelConfig)
                let metrics = try await gestureModel.trainAsync(dataset: dataset)

                await MainActor.run {
                    trainingDataManager.trainingState = .done(metrics)
                    completedMetrics = metrics
                    showingMetricsSheet = true
                    appSettings.updateModelConfig()
                }
            } catch {
                await MainActor.run {
                    trainingDataManager.trainingState = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func setupTrainingCallbacks() {
        gestureRecognizer.recognizer.gestureDetectionCallback = { detectedGesture in
            DispatchQueue.main.async {
                if isCollecting && detectedGesture.prediction.confidence > 0.6 {
                    handleTrainingGesture(detectedGesture)
                }
            }
        }
    }

    private func handleTrainingGesture(_ gesture: DetectedGesture) {
        guard trainingDataManager.isCollecting,
              let selected = selectedGesture,
              trainingDataManager.currentGestureId == selected.id else { return }

        let example = TrainingExample(
            handfilm: gesture.handfilm,
            gestureId: selected.id,
            userId: "current_user",
            sessionId: UUID().uuidString
        )

        trainingDataManager.addTrainingExample(example)

        currentSamples += 1
        collectionProgress = Double(currentSamples) / Double(targetSamples)

        if currentSamples >= targetSamples {
            stopCollection()
        }

        if appSettings.enableHapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Gesture Selection Card

struct GestureSelectionCard: View {
    let gesture: GestureDefinition
    let isSelected: Bool
    let sampleCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "hand.raised")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(gesture.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : .primary)

                if sampleCount > 0 {
                    Text("\(sampleCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .blue : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white : Color.blue)
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
}

// MARK: - Add Gesture Sheet

struct AddGestureSheet: View {
    @EnvironmentObject var gestureRegistry: GestureRegistry
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var showDuplicateError = false

    private var slug: String {
        GestureRegistry.slug(from: name)
    }

    private var isNameValid: Bool {
        !slug.isEmpty && !gestureRegistry.gestures.contains(where: { $0.id == slug })
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Gesture Name") {
                    TextField("e.g. Thumbs Up", text: $name)
                        .autocorrectionDisabled()

                    if !name.isEmpty {
                        HStack {
                            Text("ID:")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(slug.isEmpty ? "—" : slug)
                                .font(.caption.monospaced())
                                .foregroundColor(isNameValid ? .secondary : .red)
                        }

                        if !isNameValid && !slug.isEmpty {
                            Text("A gesture with this ID already exists.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section("Description") {
                    TextField("Describe how to perform this gesture", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Gesture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isNameValid)
                }
            }
        }
    }

    private func save() {
        gestureRegistry.addGesture(name: name.trimmingCharacters(in: .whitespaces),
                                   description: description.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}

// MARK: - Training Metrics Sheet

struct TrainingMetricsSheet: View {
    let metrics: ModelMetrics
    let gestureIds: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Summary") {
                    MetricRow(label: "Accuracy", value: String(format: "%.1f%%", metrics.accuracy * 100))
                    MetricRow(label: "Precision", value: String(format: "%.1f%%", metrics.precision * 100))
                    MetricRow(label: "Recall", value: String(format: "%.1f%%", metrics.recall * 100))
                    MetricRow(label: "F1 Score", value: String(format: "%.3f", metrics.f1Score))
                }

                Section("Timing") {
                    MetricRow(
                        label: "Training Time",
                        value: formatDuration(metrics.trainingTime)
                    )
                    MetricRow(
                        label: "Validation Time",
                        value: formatDuration(metrics.validationTime)
                    )
                }

                if !metrics.confusionMatrix.isEmpty && !gestureIds.isEmpty {
                    Section("Per-Class Accuracy") {
                        ForEach(gestureIds.indices, id: \.self) { i in
                            if i < metrics.confusionMatrix.count {
                                let row = metrics.confusionMatrix[i]
                                let total = row.reduce(0, +)
                                let correct = i < row.count ? row[i] : 0
                                let pct = total > 0 ? Float(correct) / Float(total) : 0
                                HStack {
                                    Text(gestureIds[i])
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(correct)/\(total)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.0f%%", pct * 100))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(pct >= 0.8 ? .green : pct >= 0.6 ? .orange : .red)
                                        .frame(width: 44, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Training Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins)m \(secs)s"
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView()
            .environmentObject(GestureRecognizerWrapper(recognizer: HandGestureRecognizing()))
            .environmentObject(TrainingDataManager())
            .environmentObject(AppSettings())
            .environmentObject(GestureRegistry())
    }
}
