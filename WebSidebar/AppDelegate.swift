//
//  AppDelegate.swift
//  WebSidebar
//
//  Created by ash on 12/6/24.
//

import SwiftUI
import AppKit

class FloatingWebSidebarButton: NSPanel {
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.nonactivatingPanel, .titled],
                   backing: .buffered,
                   defer: false)
        
        // Window configuration
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        styleMask.insert(.fullSizeContentView)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}

struct FloatingWebSidebarButtonView: View {
    @State private var windowPosition: CGPoint
    @State private var isDragging = false
    
    let onTap: () -> Void
    
    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        
        // Default position (top-right of the main screen)
        let mainScreen = NSScreen.main!
        _windowPosition = State(initialValue: CGPoint(
            x: mainScreen.frame.width - 60,
            y: mainScreen.frame.height - 60
        ))
    }
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
//                .background(Color.accentColor)
                .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).edgesIgnoringSafeArea(.all))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    windowPosition = CGPoint(
                        x: value.location.x - 20,
                        y: value.location.y - 20
                    )
                }
        )
    }
}

class SidebarWindow: NSPanel {
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.titled, .closable, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        
        // Window configuration
        level = .normal
        collectionBehavior = [.canJoinAllSpaces]
        
        // Position at the right edge of the screen
        guard let mainScreen = NSScreen.main else { return }
        
        let screenFrame = mainScreen.frame
        let sidebarWidth: CGFloat = 800
        
        setFrameOrigin(CGPoint(
            x: screenFrame.maxX - sidebarWidth,
            y: screenFrame.minY
        ))
        
        setContentSize(NSSize(width: sidebarWidth, height: screenFrame.height))
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}

class TransparentSidebarWindow: NSPanel {
    weak var sidebarManager: WebSidebarManager?
    
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.titled, .closable, .miniaturizable, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        
        // Transparent background
        backgroundColor = .clear
        isOpaque = false
        
        // Window configuration
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        
        // Make window ignore clicks outside
        isMovableByWindowBackground = false
        
        guard let mainScreen = NSScreen.main else { return }
        
        let screenFrame = mainScreen.frame
        let sidebarWidth: CGFloat = 800
        
        setFrameOrigin(CGPoint(
            x: screenFrame.maxX - sidebarWidth - 20,
            y: screenFrame.minY
        ))
        
        setContentSize(NSSize(width: sidebarWidth, height: screenFrame.height - 40))
    }
    
    override func resignKey() {
        super.resignKey()
        sidebarManager?.hideSidebar()
    }
}

class WebSidebarManager: NSObject {
    private var floatingButton: FloatingWebSidebarButton?
    private var sidebarWindow: TransparentSidebarWindow?
    private var isFirstToggle = true
    
    override init() {
        super.init()
        setupFloatingButton()
        setupSidebar()
    }
    
    private func setupFloatingButton() {
        guard let mainScreen = NSScreen.main else { return }
        
        let buttonRect = NSRect(
            x: mainScreen.frame.width - 75,
            y: mainScreen.frame.height - 80,
            width: 50,
            height: 50
        )
        
        floatingButton = FloatingWebSidebarButton(
            contentRect: buttonRect,
            styleMask: [.nonactivatingPanel, .titled],
            backing: .buffered,
            defer: false
        )
        
        let contentView = FloatingWebSidebarButtonView {
            self.toggleSidebar()
        }
        
        floatingButton?.contentView = NSHostingView(rootView: contentView)
        floatingButton?.makeKeyAndOrderFront(nil)
    }
    
    private func setupSidebar() {
        guard let mainScreen = NSScreen.main else { return }
        
        let screenFrame = mainScreen.frame
        let sidebarWidth: CGFloat = 800
        
        let sidebarRect = NSRect(
            x: screenFrame.maxX - sidebarWidth,
            y: screenFrame.minY,
            width: sidebarWidth,
            height: screenFrame.height
        )
        
        sidebarWindow = TransparentSidebarWindow(
            contentRect: sidebarRect,
            styleMask: [.titled, .closable, .miniaturizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        sidebarWindow?.sidebarManager = self
        
        let contentView = SidebarView(isFirstLoad: true)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        sidebarWindow?.contentView = hostingView
        sidebarWindow?.titleVisibility = .hidden
        sidebarWindow?.titlebarAppearsTransparent = true
        sidebarWindow?.styleMask.insert(.fullSizeContentView)
    }
    
    func toggleSidebar() {
        guard let sidebarWindow = sidebarWindow else { return }
        
        if sidebarWindow.isVisible {
            hideSidebar()
        } else {
            sidebarWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideSidebar() {
        sidebarWindow?.orderOut(nil)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var webSidebarManager: WebSidebarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the sidebar manager
        webSidebarManager = WebSidebarManager()
    }
}
