//
//  MessageInputXIB.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import SwiftUI

struct MessageInputBar: View {

    @State private var text: String = ""

    var onSend: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {

            // Text Field
            TextField("Aa", text: $text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.systemGray5))
                )

            // Send Button
            Button {
                guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                onSend(text)
                text = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.blue)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    MessageInputBar { message in
        print("Sent:", message)
    }
}
