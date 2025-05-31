//
//  AiChatUiApp.swift
//  AiChatUi
//
//  Created by Measna on 27/4/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SKPhotoBrowser

@main
struct AiChatUiApp: App {

    init() {
        SDWebImageDownloader.shared.config.downloadTimeout = 60
        SDWebImageDownloader.shared.config.maxConcurrentDownloads = 4
        SDImageCache.shared.config.maxMemoryCost = 50 * 1024 * 1024 // 50 MB
        SDImageCache.shared.config.shouldCacheImagesInMemory = true
        
        
        
//        SKPhotoBrowserOptions.
//        SKPhotoBrowserOptions.textAndIconColor = UIColor(Color.black)
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
