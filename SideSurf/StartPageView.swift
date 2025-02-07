//
//  StartPageView.swift
//  WebSidebar
//
//  Created by ash on 2/6/25.
//

import SwiftUI

struct StartPageView: View {
    @ObservedObject var browserModel: BrowserModel
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var historyManager: HistoryManager
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button(action: { browserModel.loadSpecificURL("https://google.com/") }) {
                    Label("searchlabel", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderless)
                .padding()
                .background(.foreground.opacity(0.2))
                .cornerRadius(12)
                
                HStack {
                    Text("bookmarksTitle")
                        .font(.title2)
                    
                    Spacer()
                    
                    Button(action: {
                        // Force a refresh of the bookmarks
                        bookmarkManager.loadBookmarks()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(bookmarkManager.bookmarks) { bookmark in
                        BookmarkTile(bookmark: bookmark, browserModel: browserModel)
                    }
                }
                
                if !historyManager.history.isEmpty {
                    Text("recentlyVisitedLabel")
                        .font(.title2)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(historyManager.history.prefix(6)) { item in
                                RecentTile(item: item, browserModel: browserModel)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Refresh bookmarks when the view appears
            bookmarkManager.loadBookmarks()
        }
    }
}

struct BookmarkTile: View {
    let bookmark: Bookmark
    @ObservedObject var browserModel: BrowserModel
    
    var body: some View {
        Button(action: {
            browserModel.loadSpecificURL(bookmark.url)
        }) {
            VStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                Text(bookmark.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.foreground.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentTile: View {
    let item: HistoryItem
    @ObservedObject var browserModel: BrowserModel
    
    var body: some View {
        Button(action: {
            browserModel.loadSpecificURL(item.url)
        }) {
            VStack(alignment: .leading) {
                Text(item.title)
                    .lineLimit(2)
                    .font(.headline)
                Text(item.url)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200)
            .padding()
            .background(.foreground.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
