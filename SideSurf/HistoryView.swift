//
//  HistoryView.swift
//  WebSidebar
//
//  Created by ash on 2/6/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            ForEach(historyManager.history) { item in
                HistoryItemView(item: item)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("historyTitle")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    historyManager.clearHistory()
                }
                ) {
                    Label("clearHistoryLabel", systemImage: "xmark.bin")
                }
            }
        }
    }
}

struct HistoryItemView: View {
    let item: HistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
            Text(item.url)
                .font(.caption)
                .foregroundColor(.gray)
            Text(item.timestamp, style: .date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
