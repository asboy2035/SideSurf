//
//  SideSurfApp.swift
//  SideSurf
//
//  Created by ash on 2/7/25.
//

import SwiftUI
import AppKit

@main
struct SideSurfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
