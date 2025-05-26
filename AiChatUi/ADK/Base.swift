//
//  Base.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

struct Base<T : Decodable> : Decodable, Responable {
    let data: T?
}
