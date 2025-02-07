//
//  ContentView.swift
//  WebSidebar
//
//  Created by ash on 12/6/24.
//

import SwiftUI
import WebKit
import Luminare
import LaunchAtLogin

class ContentWindowController: NSObject {
    private var window: NSWindow?

    static let shared = ContentWindowController()
    
    private override init() {
        super.init()
    }

    func showContentView() {
        if window == nil {
            let View = ContentView()
            let hostingController = NSHostingController(rootView: View)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            window.center()
            window.contentViewController = hostingController
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)

            self.window = window
        }

        window?.makeKeyAndOrderFront(nil)
    }
}

struct ContentView: View {
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var historyManager = HistoryManager()
    @State private var currentTab = "home"
    
    var body: some View {
        NavigationView {
            List {
                LuminareSection("appName") {
                    Button(action: { currentTab = "home" }) {
                        Label("homeLabel", systemImage: "house")
                    }
                }
                .buttonStyle(LuminareButtonStyle())
                
                LuminareSection("contentSection") {
                    Button(action: { currentTab = "bookmarks" }) {
                        Label("bookmarksTitle", systemImage: "bookmark")
                    }
                    Button(action: { currentTab = "history" }) {
                        Label("historyTitle", systemImage: "book")
                    }
                }
                .buttonStyle(LuminareButtonStyle())
            }
            .frame(minWidth: 200)
            
            VStack {
                switch currentTab {
                    case "home": WelcomeView()
                    case "bookmarks": BookmarksView(bookmarkManager: bookmarkManager)
                    case "history": HistoryView(historyManager: historyManager)
                    default: WelcomeView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        AboutWindowController.shared.showAboutView()
                    }
                    ) {
                        Label("aboutMenuLabel", systemImage: "info.circle")
                    }
                }
            }
            .frame(minWidth: 450)
            .background(.background.opacity(0.4))
            .cornerRadius(8)
            .padding(8)
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow).edgesIgnoringSafeArea(.all))
        .frame(minWidth: 700, minHeight: 400)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("welcomeLabel")
                .font(.title)
            LaunchAtLogin.Toggle("\(NSLocalizedString("launchAtLoginLabel", comment: "Launch at login toggle"))")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("homeLabel")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    WebSidebarManager.shared.toggleSidebar()
                }
                ) {
                    Label("toggleSidebarLabel", systemImage: "globe")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
