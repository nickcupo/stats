//
//  widget.swift
//  Kit
//
//  Created by Serhiy Mytrovtsiy on 10/04/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

public enum widget_t: String {
    case unknown = ""
    case mini = "mini"
    case lineChart = "line_chart"
    case barChart = "bar_chart"
    case pieChart = "pie_chart"
    case networkChart = "network_chart"
    case speed = "speed"
    case battery = "battery"
    case batteryDetails = "battery_details"
    case stack = "sensors" // to replace
    case memory = "memory"
    case label = "label"
    case tachometer = "tachometer"
    case state = "state"
    case text = "text"
    
    public func new(module: String, config: NSDictionary, defaultWidget: widget_t) -> SWidget? {
        guard let widgetConfig: NSDictionary = config[self.rawValue] as? NSDictionary else { return nil }
        
        var image: NSImage? = nil
        var preview: widget_p? = nil
        var item: widget_p? = nil
        
        switch self {
        case .mini:
            preview = Mini(title: module, config: widgetConfig, preview: true)
            item = Mini(title: module, config: widgetConfig, preview: false)
        case .lineChart:
            preview = LineChart(title: module, config: widgetConfig, preview: true)
            item = LineChart(title: module, config: widgetConfig, preview: false)
        case .barChart:
            preview = BarChart(title: module, config: widgetConfig, preview: true)
            item = BarChart(title: module, config: widgetConfig, preview: false)
        case .pieChart:
            preview = PieChart(title: module, config: widgetConfig, preview: true)
            item = PieChart(title: module, config: widgetConfig, preview: false)
        case .networkChart:
            preview = NetworkChart(title: module, config: widgetConfig, preview: true)
            item = NetworkChart(title: module, config: widgetConfig, preview: false)
        case .speed:
            preview = SpeedWidget(title: module, config: widgetConfig, preview: true)
            item = SpeedWidget(title: module, config: widgetConfig, preview: false)
        case .battery:
            preview = BatteryWidget(title: module, preview: true)
            item = BatteryWidget(title: module, preview: false)
        case .batteryDetails:
            preview = BatteryDetailsWidget(title: module, preview: true)
            item = BatteryDetailsWidget(title: module, preview: false)
        case .stack:
            preview = StackWidget(title: module, config: widgetConfig, preview: true)
            item = StackWidget(title: module, config: widgetConfig, preview: false)
        case .memory:
            preview = MemoryWidget(title: module, config: widgetConfig, preview: true)
            item = MemoryWidget(title: module, config: widgetConfig, preview: false)
        case .label:
            preview = Label(title: module, config: widgetConfig)
            item = Label(title: module, config: widgetConfig)
        case .tachometer:
            preview = Tachometer(title: module, preview: true)
            item = Tachometer(title: module, preview: false)
        case .state:
            preview = DotWidget(title: module, config: widgetConfig, preview: true)
            item = DotWidget(title: module, config: widgetConfig, preview: false)
        case .text:
            preview = TextWidget(title: module, preview: true)
            item = TextWidget(title: module, preview: false)
        default: break
        }
        
        if let view = preview {
            var width: CGFloat = view.bounds.width
            
            switch preview {
            case is Mini:
                if module == "Battery" {
                    width = view.bounds.width + 3
                }
            case is BarChart:
                if module == "GPU" || module == "RAM" || module == "Disk" || module == "Battery" {
                    width = 11 + (Constants.Widget.margin.x*2)
                } else if module == "Sensors" {
                    width = 22 + (Constants.Widget.margin.x*2)
                } else if module == "CPU" {
                    width = 30 + (Constants.Widget.margin.x*2)
                }
            case is StackWidget:
                if module == "Sensors" {
                    width = 25
                } else if module == "Clock" {
                    width = 114
                }
            case is MemoryWidget:
                width = view.bounds.width + 8 + Constants.Widget.spacing*2
            case is BatteryWidget:
                width = view.bounds.width - 3
            default: width = view.bounds.width
            }
            
            let r = NSRect(
                x: -view.frame.origin.x/2,
                y: 0,
                width: width - view.frame.origin.x,
                height: view.bounds.height
            )
            image = NSImage(data: view.dataWithPDF(inside: r))
        }
        
        if let item = item, let image = image {
            return SWidget(self, defaultWidget: defaultWidget, module: module, item: item, image: image)
        }
        
        return nil
    }
    
    public func name() -> String {
        switch self {
        case .mini: return localizedString("Mini widget")
        case .lineChart: return localizedString("Line chart widget")
        case .barChart: return localizedString("Bar chart widget")
        case .pieChart: return localizedString("Pie chart widget")
        case .networkChart: return localizedString("Network chart widget")
        case .speed: return localizedString("Speed widget")
        case .battery: return localizedString("Battery widget")
        case .batteryDetails: return localizedString("Battery details widget")
        case .stack: return localizedString("Stack widget")
        case .memory: return localizedString("Memory widget")
        case .label: return localizedString("Label widget")
        case .tachometer: return localizedString("Tachometer widget")
        case .state: return localizedString("State widget")
        case .text: return localizedString("Text widget")
        default: return ""
        }
    }
}
extension widget_t: CaseIterable {}

public protocol widget_p: NSView {
    var widthHandler: (() -> Void)? { get set }
    var onClick: (() -> Void)? { get set }
    
    func settings() -> NSView
}

open class WidgetWrapper: NSView, widget_p {
    public var type: widget_t
    public var title: String
    public var widthHandler: (() -> Void)? = nil
    public var onClick: (() -> Void)? = nil
    public var shadowSize: CGSize
    internal var queue: DispatchQueue
    
    public init(_ type: widget_t, title: String, frame: NSRect) {
        self.type = type
        self.title = title
        self.shadowSize = frame.size
        self.queue = DispatchQueue(label: "eu.exelban.Stats.WidgetWrapper.\(type.rawValue).\(title)")
        
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setWidth(_ width: CGFloat) {
        var newWidth = width
        if width == 0 || width == 1 {
            newWidth = self.emptyView()
        }
        
        guard self.shadowSize.width != newWidth else { return }
        self.shadowSize.width = newWidth
        
        DispatchQueue.main.async {
            self.setFrameSize(NSSize(width: newWidth, height: self.frame.size.height))
            self.widthHandler?()
        }
    }
    
    public func emptyView() -> CGFloat {
        let size: CGFloat = 15
        let lineWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        let offset = lineWidth / 2
        let width: CGFloat = (Constants.Widget.margin.x*2) + size + (lineWidth*2)
        
        NSColor.textColor.set()
        
        var circle = NSBezierPath()
        circle = NSBezierPath(ovalIn: CGRect(x: Constants.Widget.margin.x+offset, y: 1+offset, width: size, height: size))
        circle.stroke()
        circle.lineWidth = lineWidth
        
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 3, y: 3.5))
        line.line(to: NSPoint(x: 13.5, y: 14))
        line.lineWidth = lineWidth
        line.stroke()
        
        return width
    }
    
    public func redraw() {
        DispatchQueue.main.async { [weak self] in
            self?.needsDisplay = true
        }
    }
    
    open func settings() -> NSView { return NSView() }
    
    open override func mouseDown(with event: NSEvent) {
        if let f = self.onClick {
            f()
            return
        }
        super.mouseDown(with: event)
    }
}

public class SWidget {
    public let type: widget_t
    public let defaultWidget: widget_t
    public let module: String
    public let image: NSImage
    public var item: widget_p
    
    public var isActive: Bool {
        get { self.list.contains{ $0 == self.type } }
        set {
            if newValue {
                self.list.append(self.type)
            } else {
                self.list.removeAll{ $0 == self.type }
            }
        }
    }
    
    public var toggleCallback: ((widget_t, Bool) -> Void)? = nil
    public var sizeCallback: (() -> Void)? = nil
    
    public var log: NextLog {
        NextLog.shared.copy(category: self.module)
    }
    public var position: Int {
        get { Store.shared.int(key: "\(self.module)_\(self.type)_position", defaultValue: 0) }
        set { Store.shared.set(key: "\(self.module)_\(self.type)_position", value: newValue) }
    }
    
    private var keepMenuBarPosition: Bool {
       Store.shared.bool(key: "keep_menubar_positions", defaultValue: false)
    }
    
    private var list: [widget_t] {
        get {
            let string = Store.shared.string(key: "\(self.module)_widget", defaultValue: self.defaultWidget.rawValue)
            return string.split(separator: ",").map{ (widget_t(rawValue: String($0)) ?? .unknown)}
        }
        set { Store.shared.set(key: "\(self.module)_widget", value: newValue.map{ $0.rawValue }.joined(separator: ",")) }
    }
    
    private var menuBarItem: NSStatusItem? = nil
    private var hoverTracker: MenuBarHoverTracker? = nil
    private var originX: CGFloat
    
    public init(_ type: widget_t, defaultWidget: widget_t, module: String, item: widget_p, image: NSImage) {
        self.type = type
        self.module = module
        self.item = item
        self.defaultWidget = defaultWidget
        self.image = image
        self.originX = item.frame.origin.x
        
        self.item.widthHandler = { [weak self] in
            self?.sizeCallback?()
            if let s = self, let item = s.menuBarItem, item.length != s.item.frame.width {
                item.length = s.item.frame.width
            }
        }
        self.item.identifier = NSUserInterfaceItemIdentifier(self.type.rawValue)
    }
    
    // show item in the menu bar
    public func enable() {
        guard self.isActive else { return }
        self.toggleCallback?(self.type, true)
        debug("widget \(self.type.rawValue) enabled", log: self.log)
    }
    
    // remove item from the menu bar
    public func disable() {
        self.toggleCallback?(self.type, false)
        debug("widget \(self.type.rawValue) disabled", log: self.log)
    }
    
    // toggle the widget
    public func toggle(_ state: Bool? = nil) {
        var newState: Bool = !self.isActive
        if let state = state {
            newState = state
        }
        
        if self.isActive == newState {
            return
        }
        
        self.isActive = newState
        
        if !self.isActive {
            self.disable()
        } else {
            self.enable()
        }
        
        NotificationCenter.default.post(name: .toggleWidget, object: nil, userInfo: ["module": self.module])
    }
    
    public func setMenuBarItem(state: Bool) {
        if state {
            if self.keepMenuBarPosition {
                restoreNSStatusItemPosition(id: "\(self.module)_\(self.type.rawValue)")
            }
            DispatchQueue.main.async(execute: {
                guard self.menuBarItem == nil else { return }
                self.menuBarItem = NSStatusBar.system.statusItem(withLength: self.item.frame.width)
                DispatchQueue.main.async(execute: {
                    self.menuBarItem?.autosaveName = "\(self.module)_\(self.type.rawValue)"
                })
                if self.item.frame.origin.x != self.originX {
                    self.item.setFrameOrigin(NSPoint(x: self.originX, y: self.item.frame.origin.y))
                }
                self.menuBarItem?.button?.addSubview(self.item)
                self.menuBarItem?.button?.image = NSImage()
                self.menuBarItem?.button?.toolTip = "\(localizedString(self.module)): \(self.type.name())"
                
                if let item = self.menuBarItem, !item.isVisible {
                    self.menuBarItem?.isVisible = true
                }
                
                self.menuBarItem?.button?.target = self
                self.menuBarItem?.button?.action = #selector(self.togglePopup)
                self.menuBarItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
                
                if let button = self.menuBarItem?.button {
                    weak let widget = self
                    self.hoverTracker = MenuBarHoverTracker(button: button) {
                        widget?.openPopup(hover: true)
                    }
                }
            })
        } else {
            DispatchQueue.main.async(execute: {
                guard let item = self.menuBarItem else { return }
                if self.keepMenuBarPosition {
                    saveNSStatusItemPosition(id: "\(self.module)_\(self.type.rawValue)")
                }
                self.hoverTracker?.detach()
                self.hoverTracker = nil
                NSStatusBar.system.removeStatusItem(item)
                self.menuBarItem = nil
            })
        }
    }
    
    // re-create the standalone menu bar item so it picks up the app's status item spacing
    internal func recreateMenuBarItem() {
        guard self.menuBarItem != nil else { return }
        DispatchQueue.main.async(execute: {
            guard let item = self.menuBarItem else { return }
            saveNSStatusItemPosition(id: "\(self.module)_\(self.type.rawValue)")
            self.hoverTracker?.detach()
            self.hoverTracker = nil
            NSStatusBar.system.removeStatusItem(item)
            self.menuBarItem = nil
            self.item.removeFromSuperview()
            restoreNSStatusItemPosition(id: "\(self.module)_\(self.type.rawValue)")
            self.setMenuBarItem(state: true)
        })
    }
    
    @objc private func togglePopup() {
        self.hoverTracker?.noteClick()
        self.openPopup(hover: false)
    }
    
    private func openPopup(hover: Bool) {
        if let item = self.menuBarItem, let window = item.button?.window {
            var userInfo: [String: Any] = [
                "module": self.module,
                "widget": self.type,
                "origin": window.frame.origin,
                "center": window.frame.width/2
            ]
            if let button = item.button {
                userInfo["button"] = button
            }
            if hover {
                userInfo["hover"] = true
            }
            NotificationCenter.default.post(name: .togglePopup, object: nil, userInfo: userInfo)
        }
    }
}

/// Applies the user's menu bar spacing to the padding macOS draws around this app's status items.
///
/// AppKit reads `NSStatusItemSpacing` through the app's own user defaults, and uses half of it as the
/// inset on each side of every status item of the app. Setting it in the app's domain therefore only
/// affects Stats' items. The value is read when an item is created, so items are re-created after a change.
public enum MenuBarSystemSpacing {
    public static let key = "NSStatusItemSpacing"
    
    /// The value macOS uses when the app does not override it (the user's global setting, or 16).
    public static var systemDefault: CGFloat {
        if let value = CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost) as? NSNumber {
            return CGFloat(truncating: value)
        }
        if let value = CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? NSNumber {
            return CGFloat(truncating: value)
        }
        return 16
    }
    
    /// Spacing to request for this app's items so that the gap between Stats widgets follows the user's value.
    /// In combined mode the single block needs (spacing - neighbour inset) on each side; otherwise each item
    /// contributes half of the gap to its neighbour.
    public static func desired(spacing: CGFloat, combined: Bool) -> CGFloat {
        let neighbourInset = systemDefault / 2
        let ownInset = combined ? max(0, spacing - neighbourInset) : spacing / 2
        return (ownInset * 2).rounded()
    }
    
    /// Writes (or clears) the override. Call before status items are created, and again after a change.
    public static func apply() {
        let defaults = UserDefaults.standard
        guard let spacing = Constants.Widget.userSpacing else {
            if defaults.object(forKey: key) != nil {
                defaults.removeObject(forKey: key)
            }
            return
        }
        let combined = Store.shared.bool(key: "CombinedModules", defaultValue: false)
        let value = Int(desired(spacing: spacing, combined: combined))
        if defaults.object(forKey: key) as? Int != value {
            defaults.set(value, forKey: key)
        }
    }
}

/// Watches the mouse over a menu bar button and fires a handler when the cursor rests on it,
/// if the "open popup on hover" option is enabled.
public class MenuBarHoverTracker: NSResponder {
    public static var isEnabled: Bool {
        Store.shared.bool(key: "popup_on_hover", defaultValue: false)
    }
    public static let delay: TimeInterval = 0.1
    
    /// true while any popup is already open, so moving to another item switches without delay
    public static var isPopupVisible: Bool {
        NSApplication.shared.windows.contains(where: { $0 is PopupWindow && $0.isVisible })
    }
    
    /// true while a popup is pinned by a click; hover leaves everything alone until it is closed
    public static var isPinnedPopupVisible: Bool {
        NSApplication.shared.windows.contains(where: { ($0 as? PopupWindow)?.isPinned == true && $0.isVisible })
    }
    
    private weak var button: NSView?
    private var trackingArea: NSTrackingArea? = nil
    private var timer: Timer? = nil
    private let handler: () -> Void
    private var lastClick: Date = .distantPast
    /// a click on the item makes AppKit refresh its tracking area, which fires a spurious mouseEntered;
    /// hover is ignored for this long after a click so a click never re-opens what it just closed
    private let clickGrace: TimeInterval = 0.5
    
    public init(button: NSView, handler: @escaping () -> Void) {
        self.button = button
        self.handler = handler
        super.init()
        
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        button.addTrackingArea(area)
        self.trackingArea = area
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.detach()
    }
    
    public func detach() {
        self.timer?.invalidate()
        self.timer = nil
        if let area = self.trackingArea, let button = self.button {
            button.removeTrackingArea(area)
        }
        self.trackingArea = nil
    }
    
    /// call when the item is clicked
    public func noteClick() {
        self.lastClick = Date()
        self.timer?.invalidate()
        self.timer = nil
    }
    
    private var recentlyClicked: Bool {
        Date().timeIntervalSince(self.lastClick) < self.clickGrace
    }
    
    public override func mouseEntered(with event: NSEvent) {
        guard MenuBarHoverTracker.isEnabled, !self.recentlyClicked, !MenuBarHoverTracker.isPinnedPopupVisible else { return }
        self.timer?.invalidate()
        self.timer = nil
        
        if MenuBarHoverTracker.isPopupVisible {
            self.handler()
            return
        }
        
        let timer = Timer(timeInterval: MenuBarHoverTracker.delay, repeats: false) { [weak self] _ in
            self?.timer = nil
            guard let s = self, MenuBarHoverTracker.isEnabled, !s.recentlyClicked, !MenuBarHoverTracker.isPinnedPopupVisible else { return }
            s.handler()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    public override func mouseExited(with event: NSEvent) {
        self.timer?.invalidate()
        self.timer = nil
    }
}

public class MenuBar {
    public var callback: (() -> Void)? = nil
    public var widgets: [SWidget] = []
    
    private var moduleName: String
    private var menuBarItem: NSStatusItem? = nil
    private var hoverTracker: MenuBarHoverTracker? = nil
    private var queue: DispatchQueue
    
    private var combinedModules: Bool {
        Store.shared.bool(key: "CombinedModules", defaultValue: false)
    }
    
    public var view: MenuBarView = MenuBarView()
    public var oneView: Bool = false
    public var activeWidgets: [SWidget] {
        self.widgets.filter({ $0.isActive })
    }
    public var sortedWidgets: [widget_t] {
        get {
            var list: [widget_t: Int] = [:]
            self.activeWidgets.forEach { (w: SWidget) in
                list[w.type] = w.position
            }
            return list.sorted { $0.1 < $1.1 }.map{ $0.key }
        }
    }
    
    private var _active: Bool = false
    public var active: Bool {
        get { self.queue.sync { self._active } }
        set { self.queue.sync { self._active = newValue } }
    }
    
    init(moduleName: String) {
        self.moduleName = moduleName
        self.queue = DispatchQueue(label: "eu.exelban.Stats.MenuBar.\(moduleName)")
        self.oneView = Store.shared.bool(key: "\(self.moduleName)_oneView", defaultValue: self.oneView)
        self.view.identifier = NSUserInterfaceItemIdentifier(rawValue: moduleName)
        
        if self.combinedModules {
            self.oneView = true
        } else {
            self.setupMenuBarItem(self.oneView)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(listenForOneView), name: .toggleOneView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForWidgetRearrange), name: .widgetRearrange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForSpacingChange), name: .menuBarSpacing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForRecreate), name: .menuBarRecreate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .widgetRearrange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .menuBarSpacing, object: nil)
        NotificationCenter.default.removeObserver(self, name: .menuBarRecreate, object: nil)
    }
    
    public func append(_ widget: SWidget) {
        widget.toggleCallback = { [weak self] (type, state) in
            if let s = self, s.oneView {
                if state, let w = s.activeWidgets.first(where: { $0.type == type }) {
                    DispatchQueue.main.async(execute: {
                        s.recalculateWidth()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            s.view.addWidget(w.item)
                            s.view.recalculate(s.sortedWidgets)
                        }
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        s.view.removeWidget(type: type)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            s.recalculateWidth()
                            s.view.recalculate(s.sortedWidgets)
                        }
                    })
                }
            } else {
                widget.setMenuBarItem(state: state)
            }
        }
        widget.sizeCallback = { [weak self] in
            self?.recalculateWidth()
        }
        self.widgets.append(widget)
    }
    
    public func enable() {
        if self.oneView && !self.combinedModules {
            self.setupMenuBarItem(true)
        }
        self.active = true
        self.widgets.forEach{ $0.enable() }
        self.callback?()
    }
    
    public func disable() {
        self.widgets.forEach{ $0.disable() }
        self.active = false
        if self.oneView {
            self.setupMenuBarItem(false)
        }
        self.callback?()
    }
    
    private func setupMenuBarItem(_ state: Bool) {
        DispatchQueue.main.async(execute: {
            if state && self.active {
                guard self.menuBarItem == nil else { return }
                restoreNSStatusItemPosition(id: self.moduleName)
                self.menuBarItem = NSStatusBar.system.statusItem(withLength: 0)
                DispatchQueue.main.async(execute: {
                    self.menuBarItem?.autosaveName = self.moduleName
                })
                self.menuBarItem?.isVisible = true
                
                self.menuBarItem?.button?.addSubview(self.view)
                self.menuBarItem?.button?.image = NSImage()
                self.menuBarItem?.button?.toolTip = "\(localizedString(self.moduleName))"
                self.menuBarItem?.button?.target = self
                self.menuBarItem?.button?.action = #selector(self.togglePopup)
                self.menuBarItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
                
                if let button = self.menuBarItem?.button {
                    weak let menuBar = self
                    self.hoverTracker = MenuBarHoverTracker(button: button) {
                        menuBar?.openPopup(hover: true)
                    }
                }
                
                self.recalculateWidth()
            } else if let item = self.menuBarItem {
                saveNSStatusItemPosition(id: self.moduleName)
                self.hoverTracker?.detach()
                self.hoverTracker = nil
                NSStatusBar.system.removeStatusItem(item)
                self.menuBarItem = nil
            }
        })
    }
    
    private func recalculateWidth() {
        guard self.oneView, self.active else { return }
        
        let w = self.activeWidgets.isEmpty ? 0 : self.activeWidgets.map({ $0.item.frame.width }).reduce(0, +) +
            (CGFloat(self.activeWidgets.count - 1) * Constants.Widget.gap) +
            Constants.Widget.oneViewPadding * 2
        self.menuBarItem?.length = w
        self.view.setFrameOrigin(NSPoint(x: 0, y: 0))
        self.view.setFrameSize(NSSize(width: w, height: Constants.Widget.height))
        
        self.view.recalculate(self.sortedWidgets)
        self.callback?()
    }
    
    @objc private func togglePopup() {
        self.hoverTracker?.noteClick()
        self.openPopup(hover: false)
    }
    
    private func openPopup(hover: Bool) {
        if let item = self.menuBarItem, let window = item.button?.window {
            var userInfo: [String: Any] = [
                "module": self.moduleName,
                "origin": window.frame.origin,
                "center": window.frame.width/2
            ]
            if let button = item.button {
                userInfo["button"] = button
            }
            if hover {
                userInfo["hover"] = true
            }
            NotificationCenter.default.post(name: .togglePopup, object: nil, userInfo: userInfo)
        }
    }
    
    @objc private func listenForSpacingChange(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            if self.oneView {
                self.recalculateWidth()
            }
        })
    }
    
    // re-create this module's status items so they pick up the app's status item spacing
    @objc private func listenForRecreate(_ notification: Notification) {
        guard self.active else { return }
        if self.combinedModules {
            return
        }
        if self.oneView {
            guard self.menuBarItem != nil else { return }
            self.setupMenuBarItem(false)
            self.setupMenuBarItem(true)
        } else {
            self.activeWidgets.forEach { $0.recreateMenuBarItem() }
        }
    }
    
    @objc private func listenForOneView(_ notification: Notification) {
        if notification.userInfo?["module"] as? String == nil {
            self.toggleOneView()
        } else if let name = notification.userInfo?["module"] as? String, name == self.moduleName, self.active {
            self.toggleOneView()
        }
    }
    
    private func toggleOneView() {
        self.activeWidgets.forEach { (w: SWidget) in
            w.disable()
        }
        
        if self.combinedModules {
            self.oneView = true
            self.setupMenuBarItem(false)
        } else if self.active {
            self.oneView = Store.shared.bool(key: "\(self.moduleName)_oneView", defaultValue: self.oneView)
            self.setupMenuBarItem(self.oneView)
        }
        
        self.activeWidgets.forEach { (w: SWidget) in
            w.enable()
        }
    }
    
    @objc private func listenForWidgetRearrange(_ notification: Notification) {
        guard let name = notification.userInfo?["module"] as? String, name == self.moduleName else {
            return
        }
        self.view.recalculate(self.sortedWidgets)
    }
}

public class MenuBarView: NSView {
    init() {
        super.init(frame: NSRect.zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addWidget(_ view: NSView) {
        self.addSubview(view)
    }
    
    public func removeWidget(type: widget_t) {
        if let view = self.subviews.first(where: { $0.identifier == NSUserInterfaceItemIdentifier(type.rawValue) }) {
            view.removeFromSuperview()
        }
    }
    
    public func recalculate(_ list: [widget_t] = []) {
        var x: CGFloat = Constants.Widget.oneViewPadding
        list.forEach { (type: widget_t) in
            if let view = self.subviews.first(where: { $0.identifier == NSUserInterfaceItemIdentifier(type.rawValue) }) {
                view.setFrameOrigin(NSPoint(x: x, y: view.frame.origin.y))
                x = view.frame.origin.x + view.frame.width + Constants.Widget.gap
            }
        }
    }
}
