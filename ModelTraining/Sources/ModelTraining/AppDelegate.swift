import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create and show main window
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(self)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
