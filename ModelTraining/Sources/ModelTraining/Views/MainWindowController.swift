import Cocoa

class MainWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Configure window
        window?.title = "Camera Gestures - Model Training"
        window?.setContentSize(NSSize(width: 1200, height: 800))
        window?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        
        // Create main view controller
        let mainViewController = MainViewController()
        window?.contentViewController = mainViewController
    }
    
    convenience init() {
        self.init(window: NSWindow())
    }
}
