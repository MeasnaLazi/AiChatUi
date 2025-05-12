//
//  AnyMessageBaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

struct MessageView: Identifiable, Equatable {
    let id: UUID = UUID()
    let viewProvider: () -> AnyView
    private let model: any BaseMessageView

    init(_ model: some BaseMessageView) {
        self.model = model
        self.viewProvider = { model.body }
    }

    func getBody() -> AnyView {
        viewProvider()
    }
    
    func getModel() -> BaseMessageView {
        model
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

