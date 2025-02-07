//
//  HistoryItem.swift
//  WebSidebar
//
//  Created by ash on 2/6/25.
//


import Foundation

struct HistoryItem: Identifiable, Codable {
    let id = UUID()
    let url: String
    let title: String
    let timestamp: Date
}

class HistoryManager: ObservableObject {
    @Published var history: [HistoryItem] = []
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadHistory()
    }
    
    func addItem(url: String, title: String) {
        let item = HistoryItem(url: url, title: title, timestamp: Date())
        history.insert(item, at: 0)
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: "browserHistory"),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: "browserHistory")
        }
    }
}