//
//  AiChatUiApp.swift
//  AiChatUi
//
//  Created by Measna on 27/4/25.
//

import SwiftUI
import SDWebImageSwiftUI

@main
struct AiChatUiApp: App {

    init() {
        SDWebImageDownloader.shared.config.downloadTimeout = 60
        SDWebImageDownloader.shared.config.maxConcurrentDownloads = 6
        SDImageCache.shared.config.maxMemoryCost = 50 * 1024 * 1024 // 50 MB
        SDImageCache.shared.config.shouldCacheImagesInMemory = true
        
        RenderViewContext.shared.registerRenderView(model: AirbnbRenderView.self)
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
