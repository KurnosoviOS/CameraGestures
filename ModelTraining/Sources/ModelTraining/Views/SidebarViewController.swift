import Cocoa

enum TrainingMode: String, CaseIterable {
    case dataCollection = "Data Collection"
    case training = "Training"
    case testing = "Testing"
    case liveRecognition = "Live Recognition"
}

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarDidSelectMode(_ mode: TrainingMode)
}

class SidebarViewController: NSViewController {
    weak var delegate: SidebarViewControllerDelegate?
    
    private var outlineView: NSOutlineView!
    private var scrollView: NSScrollView!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOutlineView()
        setupLayout()
        
        // Select first mode by default
        outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }
    
    private func setupOutlineView() {
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.selectionHighlightStyle = .sourceList
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ModeColumn"))
        column.width = 250
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        
        scrollView.documentView = outlineView
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return TrainingMode.allCases.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return TrainingMode.allCases[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("ModeCell")
        
        let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
            ?? NSTableCellView()
        
        if let mode = item as? TrainingMode {
            cell.textField?.stringValue = mode.rawValue
            cell.imageView?.image = iconForMode(mode)
        }
        
        cell.identifier = cellIdentifier
        return cell
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = outlineView.selectedRow
        guard selectedRow >= 0 && selectedRow < TrainingMode.allCases.count else { return }
        
        let selectedMode = TrainingMode.allCases[selectedRow]
        delegate?.sidebarDidSelectMode(selectedMode)
    }
    
    private func iconForMode(_ mode: TrainingMode) -> NSImage? {
        switch mode {
        case .dataCollection:
            return NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil)
        case .training:
            return NSImage(systemSymbolName: "brain", accessibilityDescription: nil)
        case .testing:
            return NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
        case .liveRecognition:
            return NSImage(systemSymbolName: "video.fill", accessibilityDescription: nil)
        }
    }
}
