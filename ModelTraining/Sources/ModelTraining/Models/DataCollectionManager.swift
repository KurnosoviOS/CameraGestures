import Foundation

class DataCollectionManager {
    static let shared = DataCollectionManager()
    
    private var currentSession: TrainingSession?
    private var sessions: [TrainingSession] = []
    
    private init() {
        loadSessions()
    }
    
    // MARK: - Session Management
    
    func startNewSession(gestureName: String) {
        currentSession = TrainingSession(gestureName: gestureName)
    }
    
    func endCurrentSession() {
        guard let session = currentSession, !session.handfilms.isEmpty else { return }
        
        sessions.append(session)
        saveSessions()
        currentSession = nil
    }
    
    func addHandshot(_ handshot: Handshot) {
        currentSession?.addHandshot(handshot)
    }
    
    func addHandfilm(_ handfilm: Handfilm) {
        currentSession?.addHandfilm(handfilm)
    }
    
    // MARK: - Data Access
    
    func getAllSessions() -> [TrainingSession] {
        return sessions
    }
    
    func getSessions(for gestureName: String) -> [TrainingSession] {
        return sessions.filter { $0.gestureName == gestureName }
    }
    
    func getHandfilms(for gestureName: String) -> [Handfilm] {
        return getSessions(for: gestureName).flatMap { $0.handfilms }
    }
    
    func getAllGestureNames() -> [String] {
        return Array(Set(sessions.map { $0.gestureName })).sorted()
    }
    
    // MARK: - Persistence
    
    private var dataDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsPath.appendingPathComponent("CameraGestures/TrainingData")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: dataPath, withIntermediateDirectories: true)
        
        return dataPath
    }
    
    private func saveSessions() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        for session in sessions {
            let filename = "\(session.gestureName)_\(session.id).json"
            let fileURL = dataDirectory.appendingPathComponent(filename)
            
            do {
                let data = try encoder.encode(session)
                try data.write(to: fileURL)
            } catch {
                print("Failed to save session: \(error)")
            }
        }
    }
    
    private func loadSessions() {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: dataDirectory, 
                                                           includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            
            for file in files where file.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: file)
                    let session = try decoder.decode(TrainingSession.self, from: data)
                    sessions.append(session)
                } catch {
                    print("Failed to load session from \(file): \(error)")
                }
            }
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    // MARK: - Export
    
    func exportDataset(for gestureNames: [String]? = nil) -> URL? {
        let gestures = gestureNames ?? getAllGestureNames()
        var dataset = TrainingDataset(gestures: [:])
        
        for gesture in gestures {
            dataset.gestures[gesture] = getHandfilms(for: gesture)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(dataset)
            let exportURL = dataDirectory.appendingPathComponent("dataset_\(Date().timeIntervalSince1970).json")
            try data.write(to: exportURL)
            return exportURL
        } catch {
            print("Failed to export dataset: \(error)")
            return nil
        }
    }
}

// MARK: - Data Models

struct TrainingSession: Codable {
    let id: String
    let gestureName: String
    let timestamp: Date
    var handfilms: [Handfilm]
    
    private var currentHandfilm: Handfilm?
    
    init(gestureName: String) {
        self.id = UUID().uuidString
        self.gestureName = gestureName
        self.timestamp = Date()
        self.handfilms = []
    }
    
    mutating func addHandshot(_ handshot: Handshot) {
        if currentHandfilm == nil {
            currentHandfilm = Handfilm(gestureLabel: gestureName)
        }
        
        // Convert Handshot to Handfilm frame format
        // This is a simplified version - actual implementation would handle the conversion
        currentHandfilm?.frames.append(handshot)
        
        // Check if gesture is complete (e.g., based on duration or pause)
        if let handfilm = currentHandfilm, handfilm.frames.count > 30 { // Simplified completion check
            handfilms.append(handfilm)
            currentHandfilm = nil
        }
    }
    
    mutating func addHandfilm(_ handfilm: Handfilm) {
        handfilms.append(handfilm)
    }
}

struct TrainingDataset: Codable {
    var gestures: [String: [Handfilm]]
    
    var totalSamples: Int {
        gestures.values.reduce(0) { $0 + $1.count }
    }
}

// Simplified Handfilm for Swift (actual implementation would use C++ types)
struct Handfilm: Codable {
    let gestureLabel: String
    var frames: [Handshot]
    
    init(gestureLabel: String) {
        self.gestureLabel = gestureLabel
        self.frames = []
    }
}

// Make Handshot Codable for persistence
extension Handshot: Codable {
    enum CodingKeys: String, CodingKey {
        case landmarks, timestamp, confidence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        landmarks = try container.decode([Point3D].self, forKey: .landmarks)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        confidence = try container.decode(Float.self, forKey: .confidence)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(landmarks, forKey: .landmarks)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(confidence, forKey: .confidence)
    }
}

extension Point3D: Codable {}
