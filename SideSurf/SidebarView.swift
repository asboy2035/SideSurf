//
//  WebSidebar.swift
//  WebSidebar
//
//  Created by ash on 12/6/24.
//

import SwiftUI
import WebKit

struct SidebarView: View {
    @StateObject private var browserModel = BrowserModel()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    let isFirstLoad: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            AddressBarView(browserModel: browserModel)
                .padding()
            
            TabBarView(browserModel: browserModel)
                .padding([.horizontal, .bottom])
            
            VStack {
                if let selectedTab = browserModel.selectedTab,
                   selectedTab.urlString == "about:startpage" {
                    StartPageView(
                        browserModel: browserModel,
                        bookmarkManager: bookmarkManager,
                        historyManager: historyManager
                    )
                    .mask(RoundedRectangle(cornerRadius: 6))
                } else {
                    WebView(
                        browserModel: browserModel,
                        historyManager: historyManager,
                        preventReload: !isFirstLoad
                    )
                    .mask(RoundedRectangle(cornerRadius: 6))
                    .background(Color.clear)
                }
            }
            .padding(8)
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow).edgesIgnoringSafeArea(.all))
    }
}

struct AddressBarView: View {
    @ObservedObject var browserModel: BrowserModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            TextField("enterUrlLabel", text: $browserModel.currentURL) {
                browserModel.loadURL()
            }
            .textFieldStyle(PlainTextFieldStyle())
            .padding(8)
            .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button {
                browserModel.loadURL()
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(colorScheme == .dark ? .white : .accentColor)
                    .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct TabBarView: View {
    @ObservedObject var browserModel: BrowserModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(browserModel.tabs) { tab in
                    TabItemView(tab: tab, browserModel: browserModel)
                }
                
                Button {
                    browserModel.addNewTab()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(colorScheme == .dark ? .white : .accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct TabItemView: View {
    let tab: BrowserTab
    @ObservedObject var browserModel: BrowserModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(tab.title)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Button {
                browserModel.removeTab(tab)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(colorScheme == .dark ? .gray : .black.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(5)
        .background(browserModel.selectedTab == tab ?
                    (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.accentColor.opacity(0.2)) :
                        Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture {
            browserModel.selectTab(tab)
        }
    }
}

// Custom WKWebView subclass with additional property to track the last loaded URL
class CustomWebView: WKWebView {
    var lastLoadedURL: String?
}

struct WebView: NSViewRepresentable {
    @ObservedObject var browserModel: BrowserModel
    @ObservedObject var historyManager: HistoryManager
    let preventReload: Bool
    
    func makeNSView(context: Context) -> CustomWebView {
        let webView = CustomWebView()
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
        return webView
    }
    
    func updateNSView(_ nsView: CustomWebView, context: Context) {
        guard let selectedTab = browserModel.selectedTab,
              let url = URL(string: selectedTab.urlString) else {
            return
        }
        
        let urlHasChanged = nsView.lastLoadedURL != selectedTab.urlString
        if urlHasChanged && (!preventReload || nsView.lastLoadedURL == nil) {
            nsView.load(URLRequest(url: url))
            nsView.lastLoadedURL = selectedTab.urlString
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.title") { [weak self] result, error in
                guard let self = self, error == nil, let title = result as? String else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.parent.browserModel.updateCurrentTabTitle(title)
                    if let urlString = webView.url?.absoluteString {
                        self.parent.historyManager.addItem(url: urlString, title: title)
                    }
                }
            }
        }
    }
}
