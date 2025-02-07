//
//  Bookmark.swift
//  WebSidebar
//
//  Created by ash on 2/6/25.
//

import SwiftUI

struct Bookmark: Identifiable, Codable {
    let id = UUID()
    var title: String
    var url: String
    var iconURL: String?
}

class BookmarkManager: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadBookmarks()
    }
    
    func addBookmark(title: String, url: String) {
        let bookmark = Bookmark(title: title, url: url)
        bookmarks.append(bookmark)
        saveBookmarks()
    }
    
    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
    
    func loadBookmarks() {
        if let data = userDefaults.data(forKey: "bookmarks"),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
        }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            userDefaults.set(encoded, forKey: "bookmarks")
        }
    }
}

struct BookmarksView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddBookmark = false
    @State private var newBookmarkTitle = ""
    @State private var newBookmarkURL = ""
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(bookmarkManager.bookmarks) { bookmark in
                    BookmarkCard(bookmark: bookmark, bookmarkManager: bookmarkManager)
                }
            }
            .padding()
        }
        .navigationTitle("bookmarksTitle")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingAddBookmark = true
                }
                ) {
                    Label("addBookmarkLabel", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBookmark) {
            AddBookmarkView(
                isPresented: $showingAddBookmark,
                bookmarkManager: bookmarkManager
            )
        }
    }
}

struct BookmarkCard: View {
    let bookmark: Bookmark
    @ObservedObject var bookmarkManager: BookmarkManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Spacer()
                Button(action: {
                    bookmarkManager.removeBookmark(bookmark)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.foreground)
                }
                .buttonStyle(.borderless)
            }
            
            Text(bookmark.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(bookmark.url)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AddBookmarkView: View {
    @Binding var isPresented: Bool
    @ObservedObject var bookmarkManager: BookmarkManager
    @State private var title = ""
    @State private var url = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("titleField", text: $title)
                TextField("UrlField", text: $url)
            }
            .frame(width: 300, height: 200)
            .navigationTitle("addBookmarkLabel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancelLabel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("addLabel") {
                        bookmarkManager.addBookmark(title: title, url: url)
                        isPresented = false
                    }
                    .disabled(title.isEmpty || url.isEmpty)
                }
            }
        }
    }
}
