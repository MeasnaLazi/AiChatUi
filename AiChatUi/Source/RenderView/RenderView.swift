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
        
        let decoder = JSONDecoder()
    
        do {
            let modelRenderr = try decoder.decode(Render.self, from: data)
            self.renderView = AnyView(modelRenderr.content)
            
        } catch {
//            print("decode error: \(error.localizedDescription)")
//            print("data: \(text)")
            return nil
        }
    }
    
    var body: some View {
        renderView
    }
}
