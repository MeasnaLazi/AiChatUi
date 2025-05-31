//
//  TextOnlyMessgae.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SKPhotoBrowser

struct AirbnbRenderView {
    var pictures: [String]
}

extension AirbnbRenderView: BaseRenderView {
    
    static var render: String {
        "airbnb_listing"
    }
    
    var body: some View {
        VStack {
            ImageRowView(imageURLs: pictures.map {URL(string: "\($0)?im_w=720")!})
        }
        .padding(.bottom)
    }
}

struct ImageRowView: View {
    @State private var isDisplayImageViewer: Bool = false
    @State private var imageIndex: Int = 0
    
    let imageURLs: [URL] // expects at least 3
    let HEIGHT = 200.0
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width + 120
            let SPACE = 8.0

            HStack(spacing: SPACE) {
                if imageURLs.indices.contains(0) {
                    imageView(index: 0, width: (totalWidth * 0.5) - SPACE, height: HEIGHT)
                }

                VStack(spacing: SPACE) {

                    // Top 25%
                    if imageURLs.indices.contains(1) {
                        imageView(index: 1, width: totalWidth * 0.25, height: HEIGHT/2 - (SPACE/2))
                    }

                    // Bottom 25%
                    if imageURLs.indices.contains(2) {
                        
                        ZStack {
                            imageView(index: 2, width: totalWidth * 0.25, height: HEIGHT/2 - (SPACE/2))
                            if imageURLs.count - 3 > 0 {
                                Color.black.opacity(0.5)
                                Text("+\(imageURLs.count - 3)")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: totalWidth * 0.25, height: 100 - (SPACE/2))
                        .clipped()
                    }
                }
            }
            .cornerRadius(12)
        }
        .frame(height: HEIGHT) // constrain geometry height
        .fullScreenCover(isPresented: $isDisplayImageViewer) {
//            ImageViewer(imageURLs: imageURLs.map { URL(string: $0.absoluteString.replacingOccurrences(of: "?im_w=720", with: ""))! })
//            ZoomableImage(url: imageURLs.first!)
            PictureViewer(skPhotos: imageURLs.map { SKPhoto.photoWithImageURL($0.absoluteString.replacingOccurrences(of: "?im_w=720", with: "")) }, currentIndex: imageIndex)
        }
    }
    
    @ViewBuilder
    private func imageView(index: Int, width: Double, height: Double) -> some View {
        WebImage(url: imageURLs[index]) { image in
            image.resizable()
        } placeholder: {
            Rectangle().foregroundColor(.gray)
        }
        .onFailure { error in
            print("Image failed to load: \(imageURLs[0])")
        }
        .retryOnAppear(true)
        .indicator(.activity)
        .transition(.fade(duration: 0.5))
        .scaledToFill()
        .frame(width: width, height: height, alignment: .center)
        .clipped()
        .onTapGesture {
            imageIndex = index
            isDisplayImageViewer.toggle()
        }
    }
}
