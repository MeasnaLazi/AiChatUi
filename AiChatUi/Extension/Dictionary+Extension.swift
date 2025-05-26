//
//  Dictionary+Extensio.swift
//  AiChatUi
//
//  Created by Measna on 26/5/25.
//
import Foundation

extension Dictionary {
    func toData() -> Data {
        return try! JSONSerialization.data(withJSONObject: self)
    }
}
