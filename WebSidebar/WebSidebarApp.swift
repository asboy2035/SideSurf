//
//  WebSidebarApp.swift
//  WebSidebar
//
//  Created by ash on 12/6/24.
//

import SwiftUI
import AppKit

@main
struct WebSidebarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
