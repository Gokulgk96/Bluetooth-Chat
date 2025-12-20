//
//  ConstantChanges.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import Foundation

enum SendStatus: Equatable {
    case success(String)
    case failure(String)
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let date: Date
    let isSender: Bool
}
