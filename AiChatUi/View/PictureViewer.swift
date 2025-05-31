//
//  Untitled.swift
//  AiChatUi
//
//  Created by Measna on 31/5/25.
//

import SwiftUI
import SKPhotoBrowser

struct PictureViewer: UIViewControllerRepresentable {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var skPhotos:[SKPhoto]
    var currentIndex: Int
    
    func makeUIViewController(context: Context) -> SKPhotoBrowser {
        if colorScheme == .light {
            SKPhotoBrowserOptions.backgroundColor = UIColor.white
            SKToolbarOptions.textColor = UIColor.black
        }
        
        SKPhotoBrowserOptions.displayStatusbar = false
        SKPhotoBrowserOptions.shareExtraCaption = nil
        SKPhotoBrowserOptions.displayBackAndForwardButton = false
        SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
        SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
        SKToolbarOptions.textShadowColor = UIColor.clear
        
        let browser = SKPhotoBrowser(photos: skPhotos)
        browser.initializePageIndex(currentIndex)
        browser.delegate = context.coordinator
        
        return browser
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIViewController(_ browser: SKPhotoBrowser, context: Context) {
        browser.photos = skPhotos
        browser.currentPageIndex = currentIndex
    }
    
    class Coordinator: NSObject, SKPhotoBrowserDelegate {
        
        var control: PictureViewer
        
        init(_ control: PictureViewer) {
            self.control = control
        }
        
        func didShowPhotoAtIndex(_ browser: PictureViewer) {
            self.control.currentIndex = browser.currentIndex
        }
    }
}
