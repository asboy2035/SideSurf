//
//  BrowserModel.swift
//  WebSidebar
//
//  Created by ash on 12/6/24.
//

import Foundation
import Combine

struct BrowserTab: Identifiable, Equatable {
    let id = UUID()
    var urlString: String
    var title: String
}

class BrowserModel: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selectedTab: BrowserTab?
    @Published var currentURL: String = ""
    
    init() {
        addNewTab(url: "https://www.google.com")
    }
    
    func addNewTab(url: String = "https://") {
        let newTab = BrowserTab(urlString: url, title: "New Tab")
        tabs.append(newTab)
        selectTab(newTab)
    }
    
    func removeTab(_ tab: BrowserTab) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            
            // Select another tab if possible
            if !tabs.isEmpty {
                selectedTab = tabs[max(0, index - 1)]
            } else {
                addNewTab()
            }
        }
    }
    
    func selectTab(_ tab: BrowserTab) {
        selectedTab = tab
        currentURL = tab.urlString
    }
    
    func loadURL() {
        guard var selectedTab = selectedTab else { return }
        
        // Ensure URL has a scheme
        let urlString = currentURL.hasPrefix("http") ? currentURL : "https://\(currentURL)"
        
        selectedTab.urlString = urlString
        
        if let index = tabs.firstIndex(where: { $0.id == selectedTab.id }) {
            tabs[index] = selectedTab
            self.selectedTab = selectedTab
            currentURL = urlString
        }
    }
    
    func updateCurrentTabTitle(_ title: String) {
        guard var selectedTab = selectedTab else { return }
        selectedTab.title = title
        
        if let index = tabs.firstIndex(where: { $0.id == selectedTab.id }) {
            tabs[index] = selectedTab
            self.selectedTab = selectedTab
        }
    }
}
