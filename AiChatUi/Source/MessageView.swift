//
//  AnyMessageBaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

struct MessageView: Identifiable, Equatable {
    let id: UUID = UUID()
    private let wrapped: any MessageBaseModel
    let viewProvider: () -> AnyView

    init(_ message: some MessageBaseModel) {
        self.wrapped = message
        self.viewProvider = { message.getMessageView() }
    }

    func getMessageView() -> AnyView {
        viewProvider()
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

