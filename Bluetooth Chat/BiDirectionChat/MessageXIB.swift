//
//  MessageXIB.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import SwiftUI

struct MessageXIB: View {

    let message: String
    let userName: String
    let date: Date
    let isSender: Bool 

    var body: some View {
        HStack {
            if isSender { Spacer() }

            VStack(alignment: isSender ? .trailing : .leading, spacing: 4) {

                // Message Bubble
                Text(message)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isSender ? senderColor : receiverColor)
                    )
                    .frame(maxWidth: 260, alignment: isSender ? .trailing : .leading)

                // Timestamp
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if !isSender { Spacer() }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers
    private var senderColor: Color {
        Color(red: 0.78, green: 0.95, blue: 0.95) // light cyan
    }

    private var receiverColor: Color {
        Color(.systemGray5)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Today \(formatter.string(from: date))"
    }
}

#Preview {
    MessageXIB(
        message: "Doing good!",
        userName: "Friend",
        date: Date(),
        isSender: false
    )
    MessageXIB(
        message: "Fine. WAU?",
        userName: "Gokul",
        date: Date(),
        isSender: true
    )
}

