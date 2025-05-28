//
//  ModelView.swift
//  AiChatUi
//
//  Created by Measna on 13/5/25.
//
import SwiftUI

struct RenderView: View {
    let renderView: AnyView
    
    init?(text: String) {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        
//        print("text:\(text)")
        
        let decoder = JSONDecoder()
        
        guard let modelRender = try? decoder.decode(Render.self, from: data) else {
            return nil
        }
        
        self.renderView = AnyView(modelRender.content)
    }
    
    var body: some View {
        renderView
    }
}
