//
//  TextOnlyMessgae.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

struct StayMessageRender {
    var price: String
    var guest: String
    var link: String
    var images: [String]
}

extension StayMessageRender: BaseRenderView {
    
    static var render: String {
        "stay"
    }
    
    var body: some View {
        VStack {
            AnimatedURLImageCarouselView(imageURLs: images.map {URL(string: $0)!})
            HStack {
                Text("Allow: \(guest) guest(s)")
                Spacer()
                Text("Price: $\(price)")
            }
            Button(action: {
                if let url = URL(string: link) {
                   UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Spacer()
                    Text("View Detail")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                    
                    Spacer()
                    Image(systemName: "globe.americas")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
    }
}


struct AnimatedURLImageCarouselView: View {
    let imageURLs: [URL]

    @State private var currentIndex = 0
    @State private var direction: AnimationDirection = .none

    enum AnimationDirection {
        case left, right, none
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(imageURLs.indices, id: \.self) { index in
                        if index == currentIndex {
                            AsyncImage(url: imageURLs[index]) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: geometry.size.width, height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: 200)
                                        .clipped()
                                case .failure:
                                    Color.gray
                                        .frame(width: geometry.size.width, height: 200)
                                        .overlay(Text("Failed to load").foregroundColor(.white))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: direction == .right ? .leading : .trailing),
                                removal: .move(edge: direction == .right ? .trailing : .leading))
                            )
                            .id(index) // Required for animation to trigger correctly
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: currentIndex)
            }
            .frame(height: 200)
            .cornerRadius(10)

            if imageURLs.count > 1 {
                // Controls
                HStack {
                    Button(action: {
                        guard currentIndex > 0 else { return }
                        direction = .right
                        currentIndex -= 1
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        guard currentIndex < imageURLs.count - 1 else { return }
                        direction = .left
                        currentIndex += 1
                    }) {
                        Image(systemName: "chevron.right")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
                .foregroundColor(.white)
                .frame(height: 200)
                
                // Index label
                VStack {
                    Spacer()
                    Text("\(currentIndex + 1) / \(imageURLs.count)")
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}

