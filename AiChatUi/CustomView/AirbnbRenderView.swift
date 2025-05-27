//
//  TextOnlyMessgae.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI
import SDWebImageSwiftUI

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
    let imageURLs: [URL] // expects at least 3
    let SPACE = 8.0

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width + 120

            HStack(spacing: SPACE) {
                if imageURLs.indices.contains(0) {
                    
                    WebImage(url: imageURLs[0]) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle().foregroundColor(.gray)
                        }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFill()
                        .frame(width: (totalWidth * 0.5) - SPACE, height: 200, alignment: .center)
                        .clipped()
                    
                }

                VStack(spacing: SPACE) {
                    // Top 25% with overlay
                    if imageURLs.indices.contains(1) {
                        
                        WebImage(url: imageURLs[2]) { image in
                                image.resizable()
                            } placeholder: {
                                Rectangle().foregroundColor(.gray)
                            }
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                            .frame(width: totalWidth * 0.25, height: 100 - (SPACE/2), alignment: .center)
                            .clipped()
                    }

                    // Bottom 25%
                    if imageURLs.indices.contains(2) {
                        ZStack {
                            WebImage(url: imageURLs[1]) { image in
                                    image.resizable()
                                } placeholder: {
                                    Rectangle().foregroundColor(.gray)
                                }
                                .indicator(.activity)
                                .transition(.fade(duration: 0.5))
                                .scaledToFill()
                                .frame(width: totalWidth * 0.25, height: 100 - (SPACE/2), alignment: .center)
                                .clipped()
                            
                            Color.black.opacity(0.5)
                            Text("View All")
                                .foregroundColor(.white)
                        }
                        .frame(width: totalWidth * 0.25, height: 100 - (SPACE/2))
                        .clipped()
                    }
                }
            }
            .cornerRadius(12)
        }
        .frame(height: 200) // constrain geometry height
    }
}
