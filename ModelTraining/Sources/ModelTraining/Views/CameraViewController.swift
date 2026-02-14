import Cocoa
import AVFoundation

class CameraViewController: NSViewController {
    private var cameraPreviewView: CameraPreviewView!
    private var controlsStackView: NSStackView!
    private var startStopButton: NSButton!
    private var statusLabel: NSTextField!
    
    private var gestureRecognizer: GestureRecognizerWrapper?
    private var currentMode: TrainingMode = .dataCollection
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupGestureRecognizer()
    }
    
    private func setupUI() {
        // Camera preview
        cameraPreviewView = CameraPreviewView()
        cameraPreviewView.translatesAutoresizingMaskIntoConstraints = false
        
        // Controls
        startStopButton = NSButton(title: "Start Camera", target: self, action: #selector(startStopButtonClicked))
        startStopButton.bezelStyle = .rounded
        
        statusLabel = NSTextField(labelWithString: "Ready")
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        
        controlsStackView = NSStackView(views: [startStopButton, statusLabel])
        controlsStackView.orientation = .horizontal
        controlsStackView.spacing = 20
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(cameraPreviewView)
        view.addSubview(controlsStackView)
        
        NSLayoutConstraint.activate([
            cameraPreviewView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            cameraPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraPreviewView.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -20),
            
            controlsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlsStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            controlsStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupGestureRecognizer() {
        gestureRecognizer = GestureRecognizerWrapper()
        gestureRecognizer?.delegate = self
    }
    
    func updateMode(_ mode: TrainingMode) {
        currentMode = mode
        
        // Update UI based on mode
        switch mode {
        case .dataCollection:
            statusLabel.stringValue = "Data Collection Mode"
        case .training:
            statusLabel.stringValue = "Training Mode"
        case .testing:
            statusLabel.stringValue = "Testing Mode"
        case .liveRecognition:
            statusLabel.stringValue = "Live Recognition Mode"
        }
    }
    
    @objc private func startStopButtonClicked() {
        guard let recognizer = gestureRecognizer else { return }
        
        if recognizer.isRunning {
            recognizer.stop()
            startStopButton.title = "Start Camera"
            cameraPreviewView.stopPreview()
        } else {
            recognizer.start()
            startStopButton.title = "Stop Camera"
            cameraPreviewView.startPreview()
        }
    }
}

extension CameraViewController: GestureRecognizerDelegate {
    func gestureRecognizer(_ recognizer: GestureRecognizerWrapper, didDetectHandshot handshot: Handshot) {
        // Update preview with hand landmarks
        DispatchQueue.main.async {
            self.cameraPreviewView.updateHandLandmarks(handshot.landmarks)
        }
        
        // Handle based on current mode
        switch currentMode {
        case .dataCollection:
            // Store handshot for training data
            DataCollectionManager.shared.addHandshot(handshot)
        case .testing, .liveRecognition:
            // Process for recognition
            break
        case .training:
            // Training mode doesn't use live camera
            break
        }
    }
    
    func gestureRecognizer(_ recognizer: GestureRecognizerWrapper, didDetectGesture gesture: String, confidence: Float) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Detected: \(gesture) (\(String(format: "%.2f", confidence)))"
        }
    }
}
