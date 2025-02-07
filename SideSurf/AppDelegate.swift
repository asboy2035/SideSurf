//
//  AppDelegate.swift
//  WebSidebar
//
//  Created by ash on 12/6/24.
//

import SwiftUI
import AppKit

// MARK: - Base NSPanel
class CustomPanel: NSPanel {
    init(contentRect: NSRect, styleMask: NSWindow.StyleMask, level: NSWindow.Level) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        self.level = level
        self.isOpaque = false
        self.collectionBehavior = [.canJoinAllSpaces]
    }
    
    override var canBecomeKey: Bool { return true }
}

// MARK: - Floating Button Panel
class FloatingWebSidebarButton: CustomPanel {
    init() {
        let screen = NSScreen.main!.frame
        let buttonSize: CGFloat = 50
        let rect = NSRect(x: screen.width - 80, y: screen.height - 80, width: buttonSize, height: buttonSize)
        
        super.init(contentRect: rect, styleMask: [.nonactivatingPanel, .titled], level: .floating)
        styleMask.insert(.fullSizeContentView)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = .clear
    }
}

// MARK: - Sidebar Panel
class TransparentSidebarWindow: CustomPanel {
    weak var sidebarManager: WebSidebarManager?
    
    init() {
        let screen = NSScreen.main!.frame
        
        // Define the width of the sidebar
        let sidebarWidth: CGFloat = 800
        
        // Apply 20pt offset for top, left, and bottom
        let rect = NSRect(
            x: screen.maxX - sidebarWidth - 20, // 20pt from the left
            y: screen.minX + 20, // 20pt from the top
            width: sidebarWidth,
            height: screen.height - 60 // Subtract 40pt to account for both the top and bottom 20pt offsets
        )
        
        super.init(contentRect: rect, styleMask: [.titled, .closable, .miniaturizable, .nonactivatingPanel], level: .floating)
        
        styleMask.insert(.fullSizeContentView)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }
    
    override func resignKey() {
        super.resignKey()
        sidebarManager?.hideSidebar()
    }
}

// MARK: - Floating Button View
struct FloatingWebSidebarButtonView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sidebar Manager
class WebSidebarManager: NSObject {
    private var floatingButton: FloatingWebSidebarButton?
    private var sidebarWindow: TransparentSidebarWindow?
    
    static let shared = WebSidebarManager()
    
    override init() {
        super.init()
        setupFloatingButton()
        setupSidebar()
    }
    
    private func setupFloatingButton() {
        floatingButton = FloatingWebSidebarButton()
        floatingButton?.contentView = NSHostingView(rootView: FloatingWebSidebarButtonView { self.toggleSidebar() })
        floatingButton?.makeKeyAndOrderFront(nil)
    }
    
    private func setupSidebar() {
        sidebarWindow = TransparentSidebarWindow()
        sidebarWindow?.sidebarManager = self
        sidebarWindow?.contentView = NSHostingView(rootView: SidebarView(isFirstLoad: true))
    }
    
    func toggleSidebar() {
        guard let sidebarWindow = sidebarWindow else { return }
        sidebarWindow.isVisible ? hideSidebar() : sidebarWindow.makeKeyAndOrderFront(nil)
    }
    
    func hideSidebar() {
        sidebarWindow?.orderOut(nil)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var webSidebarManager: WebSidebarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ContentWindowController.shared.showContentView()
        webSidebarManager = WebSidebarManager()
    }
}
