import Foundation
import Combine

/// Manages the list of user-defined gestures and persists them as JSON on disk.
public class GestureRegistry: ObservableObject {

    @Published public private(set) var gestures: [GestureDefinition]

    private let storageURL: URL

    public init(storageURL: URL? = nil) {
        if let url = storageURL {
            self.storageURL = url
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.storageURL = appSupport.appendingPathComponent("gestures.json")
        }
        self.gestures = []
        self.gestures = load()
    }

    // MARK: - Public API

    /// Add a new gesture. `name` must be non-empty and produce a unique slug.
    /// - Returns: The created `GestureDefinition`, or `nil` if the name was invalid / duplicate.
    @discardableResult
    public func addGesture(name: String, description: String) -> GestureDefinition? {
        let slug = makeSlug(from: name)
        guard !slug.isEmpty, !gestures.contains(where: { $0.id == slug }) else { return nil }
        let definition = GestureDefinition(id: slug, name: name, description: description)
        gestures.append(definition)
        save()
        return definition
    }

    /// Remove a gesture by its ID.
    public func removeGesture(id: String) {
        gestures.removeAll { $0.id == id }
        save()
    }

    // MARK: - Slug Helpers

    /// Derives a stable slug from a display name ("Thumbs Up" → "thumbs_up").
    public static func slug(from name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    private func makeSlug(from name: String) -> String {
        GestureRegistry.slug(from: name)
    }

    // MARK: - Persistence

    private func load() -> [GestureDefinition] {
        guard FileManager.default.fileExists(atPath: storageURL.path),
              let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([GestureDefinition].self, from: data)
        else { return [] }
        return decoded
    }

    private func save() {
        do {
            let dir = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(gestures)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("GestureRegistry: failed to save — \(error)")
        }
    }
}
