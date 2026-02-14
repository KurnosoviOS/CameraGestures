import Foundation
import AppKit

// Entry point for macOS ModelTraining application
@main
struct ModelTrainingApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
