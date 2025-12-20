//
//  ChatView.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import SwiftUI
import CoreBluetooth

struct ChatView: View {

    var viewModel: BluetoothViewModel

    @State private var messages: [ChatMessage] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(spacing: 4) {
                Text("Connected to")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(viewModel.connectedDevice?.name ?? "Device")
                    .font(.headline)
            }
            .padding(.vertical, 8)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageXIB(
                                message: message.text,
                                userName: "",
                                date: message.date,
                                isSender: message.isSender
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.top, 12)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            // Input Bar
            MessageInputBar { text in
                sendMessage(text)
            }
            .disabled(!viewModel.isReadyToSend)
            .opacity(viewModel.isReadyToSend ? 1 : 0.5)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)

        // Observe BLE send status (iOS 17+ safe)
        .onChange(of: viewModel.lastSendStatus) {
            guard let status = viewModel.lastSendStatus else { return }

            switch status {
            case .success(let message):
                let outgoing = ChatMessage(
                    text: message,
                    date: Date(),
                    isSender: true
                )
                messages.append(outgoing)
                showAlert = false
            case .failure(let error):
                alertMessage = "Failed: \(error)"
                showAlert = true
            }

            viewModel.lastSendStatus = nil
        }
        .onChange(of: viewModel.lastRecievedStatus) {
            guard let status = viewModel.lastRecievedStatus else { return }

            switch status {
            case .success(let message):
                let outgoing = ChatMessage(
                    text: message,
                    date: Date(),
                    isSender: false
                )
                messages.append(outgoing)
                showAlert = false
            case .failure(let error):
                alertMessage = "Failed: \(error)"
                showAlert = true
            }

            viewModel.lastRecievedStatus = nil
        }
        .alert("Send Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                // none
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Send Logic
    private func sendMessage(_ text: String) {
        viewModel.sendMessage(text)
    }
}

#Preview {
    let vm = BluetoothViewModel()
    ChatView(viewModel: vm)
}
