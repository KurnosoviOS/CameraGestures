import Cocoa

class DetailViewController: NSViewController {
    private var currentMode: TrainingMode = .dataCollection
    private var containerView: NSView!
    
    // Child view controllers for each mode
    private var dataCollectionVC: DataCollectionViewController!
    private var trainingVC: TrainingViewController!
    private var testingVC: TestingViewController!
    private var liveRecognitionVC: LiveRecognitionViewController!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupChildViewControllers()
        
        // Show data collection by default
        showViewController(dataCollectionVC)
    }
    
    private func setupUI() {
        containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupChildViewControllers() {
        dataCollectionVC = DataCollectionViewController()
        trainingVC = TrainingViewController()
        testingVC = TestingViewController()
        liveRecognitionVC = LiveRecognitionViewController()
    }
    
    func updateMode(_ mode: TrainingMode) {
        currentMode = mode
        
        // Remove current child view controller
        children.forEach { child in
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        // Show appropriate view controller
        switch mode {
        case .dataCollection:
            showViewController(dataCollectionVC)
        case .training:
            showViewController(trainingVC)
        case .testing:
            showViewController(testingVC)
        case .liveRecognition:
            showViewController(liveRecognitionVC)
        }
    }
    
    private func showViewController(_ viewController: NSViewController) {
        addChild(viewController)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.width, .height]
        containerView.addSubview(viewController.view)
    }
}
