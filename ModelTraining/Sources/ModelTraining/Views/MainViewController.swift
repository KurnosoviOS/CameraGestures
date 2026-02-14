import Cocoa
import AVFoundation

class MainViewController: NSSplitViewController {
    private var sidebarViewController: SidebarViewController!
    private var cameraViewController: CameraViewController!
    private var detailViewController: DetailViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewControllers()
        configureSplitView()
    }
    
    private func setupViewControllers() {
        // Sidebar for navigation
        sidebarViewController = SidebarViewController()
        sidebarViewController.delegate = self
        
        // Camera view for hand tracking
        cameraViewController = CameraViewController()
        
        // Detail view for training/testing
        detailViewController = DetailViewController()
        
        // Add split view items
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 300
        
        let cameraItem = NSSplitViewItem(viewController: cameraViewController)
        cameraItem.minimumThickness = 400
        
        let detailItem = NSSplitViewItem(viewController: detailViewController)
        detailItem.minimumThickness = 300
        
        addSplitViewItem(sidebarItem)
        addSplitViewItem(cameraItem)
        addSplitViewItem(detailItem)
    }
    
    private func configureSplitView() {
        splitView.dividerStyle = .thin
        splitView.autosaveName = "MainSplitView"
    }
}

extension MainViewController: SidebarViewControllerDelegate {
    func sidebarDidSelectMode(_ mode: TrainingMode) {
        detailViewController.updateMode(mode)
        cameraViewController.updateMode(mode)
    }
}
