//
//  CombinedView.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 09/01/2023
//  Using Swift 5.0
//  Running on macOS 13.1
//
//  Copyright © 2023 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit



internal class CombinedView: NSObject, NSGestureRecognizerDelegate {
    private var menuBarItem: NSStatusItem? = nil
    private var hoverTracker: MenuBarHoverTracker? = nil
    private var hoverModule: String? = nil
    private var hoverTimer: Timer? = nil
    private var view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: Constants.Widget.height))
    private var popup: PopupWindow? = nil
    
    private var status: Bool {
        Store.shared.bool(key: "CombinedModules", defaultValue: false)
    }
    private var spacing: CGFloat {
        CGFloat(Int(Store.shared.string(key: "CombinedModules_spacing", defaultValue: "")) ?? 0)
    }
    private var separator: Bool {
        Store.shared.bool(key: "CombinedModules_separator", defaultValue: false)
    }
    
    private var activeModules: [Module] {
        modules.filter({ $0.enabled }).sorted(by: { $0.combinedPosition < $1.combinedPosition })
    }
    
    private var combinedModulesPopup: Bool {
        get { Store.shared.bool(key: "CombinedModules_popup", defaultValue: true) }
        set { Store.shared.set(key: "CombinedModules_popup", value: newValue) }
    }
    
    override init() {
        super.init()
        
        modules.forEach { (m: Module) in
            m.menuBar.callback = { [weak self] in
                if let s = self?.status, s {
                    DispatchQueue.main.async(execute: {
                        self?.recalculate()
                    })
                }
            }
        }
        
        self.popup = PopupWindow(title: "Combined modules", module: .combined, view: Popup()) { _ in }
        
        if self.status {
            self.enable()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(listenForOneView), name: .toggleOneView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForModuleRearrrange), name: .moduleRearrange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .moduleRearrange, object: nil)
    }
    
    public func enable() {
        self.menuBarItem = NSStatusBar.system.statusItem(withLength: 0)
        DispatchQueue.main.async(execute: {
            self.menuBarItem?.autosaveName = "CombinedModules"
        })
        self.menuBarItem?.button?.addSubview(self.view)
        self.menuBarItem?.button?.image = NSImage()
        self.menuBarItem?.button?.toolTip = localizedString("Combined modules")
        
        self.menuBarItem?.button?.target = self
        self.menuBarItem?.button?.action = #selector(self.handleClick)
        self.menuBarItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        if let button = self.menuBarItem?.button {
            self.hoverTracker = MenuBarHoverTracker(button: button) { [weak self] in
                self?.handleHover()
            }
        }
        
        DispatchQueue.main.async(execute: {
            self.recalculate()
        })
    }
    
    public func disable() {
        self.stopHoverFollow()
        self.hoverTracker?.detach()
        self.hoverTracker = nil
        if let item = self.menuBarItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        self.menuBarItem = nil
    }
    
    private func recalculate() {
        self.view.subviews.forEach({ $0.removeFromSuperview() })
        
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        // with a user-defined spacing the block's outer edges rely on the system padding only,
        // so the gap to neighbouring (native) items matches the menu bar; the padding stays between modules
        let edge: CGFloat = Constants.Widget.userSpacing == nil ? 0 : Constants.Widget.oneViewPadding
        var w: CGFloat = -edge
        visibleModules.enumerated().forEach { (i, m) in
            if i != 0 {
                w += self.spacing
                if self.separator {
                    self.view.addSubview(SeparatorLineView(frame: NSRect(x: w, y: 3, width: 1, height: Constants.Widget.height-6)))
                    w += 3 + self.spacing
                }
            }
            self.view.addSubview(m.menuBar.view)
            m.menuBar.view.setFrameOrigin(NSPoint(x: w, y: 0))
            w += m.menuBar.view.frame.width
        }
        w = max(0, w - edge)
        self.view.setFrameSize(NSSize(width: w, height: self.view.frame.height))
        self.menuBarItem?.length = w
    }
    
    // call when popup appear/disappear
    private func visibilityCallback(_ state: Bool) {}
    
    @objc private func handleClick() {
        if self.combinedModulesPopup {
            self.togglePopup(hover: false)
        } else {
            self.openModulePopup(hover: false)
        }
    }
    
    private func handleHover() {
        if self.combinedModulesPopup {
            self.togglePopup(hover: true)
        } else {
            self.openModulePopup(hover: true)
        }
    }
    
    // while a hover popup is open, follow the cursor from one module to the next inside the combined item
    private func startHoverFollow() {
        self.stopHoverFollow()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.followHover()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.hoverTimer = timer
    }
    
    private func stopHoverFollow() {
        self.hoverTimer?.invalidate()
        self.hoverTimer = nil
    }
    
    private func followHover() {
        guard MenuBarHoverTracker.isEnabled, MenuBarHoverTracker.isPopupVisible else {
            self.stopHoverFollow()
            self.hoverModule = nil
            return
        }
        guard !self.combinedModulesPopup,
              let window = self.menuBarItem?.button?.window, window.frame.contains(NSEvent.mouseLocation),
              let module = self.moduleUnderCursor(), module.name != self.hoverModule else { return }
        self.openModulePopup(hover: true)
    }
    
    private func moduleUnderCursor() -> Module? {
        guard let window = self.menuBarItem?.button?.window else { return nil }
        let location = self.view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        return visibleModules.last(where: { $0.menuBar.view.frame.minX <= location.x }) ?? visibleModules.first
    }
    
    private func openModulePopup(hover: Bool) {
        guard let window = self.menuBarItem?.button?.window, let module = self.moduleUnderCursor() else { return }
        let location = self.view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        if hover {
            self.hoverModule = module.name
            self.startHoverFollow()
        }
        
        var userInfo: [String: Any] = [
            "module": module.name,
            "origin": window.frame.origin,
            "center": window.frame.width/2
        ]
        let widgetLocation = module.menuBar.view.convert(location, from: self.view)
        let widgets = module.menuBar.activeWidgets
        if let widget = widgets.last(where: { $0.item.frame.minX <= widgetLocation.x }) ?? widgets.first {
            userInfo["widget"] = widget.type
        }
        if hover {
            userInfo["hover"] = true
        }
        NotificationCenter.default.post(name: .togglePopup, object: nil, userInfo: userInfo)
    }
    
    private func togglePopup(hover: Bool) {
        guard let popup = self.popup, let item = self.menuBarItem, let window = item.button?.window else { return }
        let openedWindows = NSApplication.shared.windows.filter{ $0 is NSPanel }
        openedWindows.forEach{ $0.setIsVisible(false) }
        
        if hover {
            // hover only ever opens the popup; closing is handled by the popup itself once the cursor leaves
            if popup.isVisible {
                popup.startHoverTracking(anchor: window.frame)
                return
            }
            NSApplication.shared.windows.filter{ $0 is PopupWindow && $0 != popup }.forEach{ $0.setIsVisible(false) }
        }
        
        if popup.occlusionState.rawValue == 8192 || hover {
            if !hover {
                popup.level = .normal
                popup.animationBehavior = .default
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            
            popup.contentView?.invalidateIntrinsicContentSize()
            
            let windowCenter = popup.contentView!.intrinsicContentSize.width / 2
            var x = window.frame.origin.x - windowCenter + window.frame.width/2
            let y = window.frame.origin.y - popup.contentView!.intrinsicContentSize.height - 3
            
            let buttonPoint = NSPoint(x: window.frame.midX, y: window.frame.midY)
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(buttonPoint) }) ?? NSScreen.main {
                if x + popup.contentView!.intrinsicContentSize.width > screen.frame.maxX {
                    x = screen.frame.maxX - popup.contentView!.intrinsicContentSize.width - 3
                }
                if x < screen.frame.minX {
                    x = screen.frame.minX + 3
                }
            }
            
            popup.setFrameOrigin(NSPoint(x: x, y: y))
            if hover {
                popup.showOnHover(anchor: window.frame)
            } else {
                popup.setIsVisible(true)
            }
        } else {
            popup.setIsVisible(false)
        }
    }
    
    @objc private func listenForOneView(_ notification: Notification) {
        guard notification.userInfo?["module"] == nil else { return }
        
        if self.status {
            self.enable()
        } else {
            self.disable()
        }
    }
    
    @objc private func listenForModuleRearrrange() {
        self.recalculate()
    }
}

private class SeparatorLineView: NSView {
    override var wantsUpdateLayer: Bool { true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        self.layer?.backgroundColor = (self.isDarkMode ? NSColor.white : NSColor.black).cgColor
    }
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }
}

private class Popup: NSStackView, Popup_p {
    fileprivate var keyboardShortcut: [UInt16] = []
    fileprivate var sizeCallback: ((NSSize) -> Void)? = nil
    
    init() {
        self.keyboardShortcut = Store.shared.array(key: "CombinedModules_popup_keyboardShortcut", defaultValue: []) as? [UInt16] ?? []
        
        super.init(frame: NSRect(x: 0, y: 0, width: Constants.Popup.width, height: 0))
        
        self.orientation = .vertical
        self.distribution = .fill
        self.alignment = .width
        self.spacing = Constants.Popup.spacing*3
        
        self.reinit()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reinit), name: .toggleModule, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
    }
    
    fileprivate func settings() -> NSView? { return nil }
    fileprivate func appear() {}
    fileprivate func disappear() {}
    fileprivate func setKeyboardShortcut(_ binding: [UInt16]) {
        self.keyboardShortcut = binding
        Store.shared.set(key: "CombinedModules_popup_keyboardShortcut", value: binding)
    }
    
    @objc private func reinit() {
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        let availableModules = modules.filter({ $0.enabled && $0.portal != nil })
        var modulesHeight: CGFloat = 0
        availableModules.forEach { (m: Module) in
            if let p = m.portal {
                modulesHeight += p.height
                self.addArrangedSubview(p)
            }
        }
        
        let h = modulesHeight + (CGFloat(availableModules.count-1)*self.spacing)
        if h > 0 {
            self.setFrameSize(NSSize(width: self.frame.width, height: h))
            self.sizeCallback?(self.frame.size)
        }
    }
}
