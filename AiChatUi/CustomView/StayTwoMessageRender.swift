//
//  TextOnlyMessgae.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

struct StayTwoMessageRender {
    var price: String
    var guest: String
    var link: String
    var images: [String]
}

extension StayTwoMessageRender: BaseRenderView {
    
    static var render: String {
        "stay2"
    }
    
    var body: some View {
        VStack {
            ImageRowView(imageURLs: images.map {URL(string: $0)!})
            HStack {
                VStack(alignment: .leading) {
                    Text("Allow: \(guest) guest(s)")
                    Text("Price: $\(price)")
                }
                Divider()
                Button(action: {
                    if let url = URL(string: link) {
                       UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Book Now")
                            .frame(maxWidth: .infinity)
                            .font(.subheadline)
                        
                        Spacer()
                        Image(systemName: "phone")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }

            .padding(.bottom, 20)
        }
    }
}

struct ImageRowView: View {
    let imageURLs: [URL] // expects at least 3

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width + 120

            HStack(spacing: 0) {
                // 50% width
                if imageURLs.indices.contains(0) {
                    AsyncImage(url: imageURLs[0]) { phase in
                        imageView(for: phase)
                    }
                    .frame(width: totalWidth * 0.5, height: 200)
                    .clipped()
                }

                VStack(spacing: 0) {
                    // Top 25% with overlay
                    if imageURLs.indices.contains(1) {
                        AsyncImage(url: imageURLs[2]) { phase in
                            imageView(for: phase)
                        }
                        .frame(width: totalWidth * 0.25, height: 100)
                        .clipped()
                    }

                    // Bottom 25%
                    if imageURLs.indices.contains(2) {
                        ZStack {
                            AsyncImage(url: imageURLs[1]) { phase in
                                imageView(for: phase)
                            }
                            Color.black.opacity(0.4)
                            Text("View All")
                                .foregroundColor(.white)
                        }
                        .frame(width: totalWidth * 0.25, height: 100)
                        .clipped()
                    }
                }
            }
            .cornerRadius(12)
        }
        .frame(height: 200) // constrain geometry height
    }

    // AsyncImage loader
    @ViewBuilder
    private func imageView(for phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            Color.gray.opacity(0.3)
        case .success(let image):
            image
                .resizable()
                .scaledToFill()
        case .failure:
            Color.red.opacity(0.3)
        @unknown default:
            Color.gray.opacity(0.3)
        }
    }
}
