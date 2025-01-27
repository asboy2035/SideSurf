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
    let isFirstLoad: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Address Bar
            AddressBarView(browserModel: browserModel)
                .background(Color.clear)
            
            // Tab Bar
            TabBarView(browserModel: browserModel)
                .background(Color.clear)
            
            // Web View Container
            WebView(browserModel: browserModel,
                    preventReload: !isFirstLoad)
                .background(Color.clear)
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow).edgesIgnoringSafeArea(.all))
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct AddressBarView: View {
    @ObservedObject var browserModel: BrowserModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            TextField("Enter URL", text: $browserModel.currentURL) {
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
                    .pointerStyle(.link)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
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
                        .pointerStyle(.link)
                        .foregroundColor(colorScheme == .dark ? .white : .accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
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
    let preventReload: Bool
    
    func makeNSView(context: Context) -> CustomWebView {
        let webView = CustomWebView()
        webView.navigationDelegate = context.coordinator
        
        // Set a modern User-Agent string
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
        
        return webView
    }
    
    func updateNSView(_ nsView: CustomWebView, context: Context) {
        guard let selectedTab = browserModel.selectedTab,
              let url = URL(string: selectedTab.urlString) else {
            return
        }
        
        // Only reload if:
        // 1. The URL has actually changed
        // 2. We're not preventing reloads OR this is a new URL
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
            // Fetch and update the tab title
            webView.evaluateJavaScript("document.title") { [weak self] result, error in
                guard let self = self, error == nil, let title = result as? String else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.parent.browserModel.updateCurrentTabTitle(title)
                }
            }
        }
    }
}
